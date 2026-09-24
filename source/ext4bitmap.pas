   unit ext4bitmap;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,ImageUtils;

function ReadExt4Info(const Device:string;var Info:TExt4Info):Boolean;
function ReadExt4BlockBitmap(const Device:string;const Info:TExt4Info;Group:UInt32;var Bitmap:TBytes):Boolean;
function GetSectorSize(const Device:string):UInt32;
function BuildUsedSectorBitmap(const Device:string;const Info:TExt4Info;var SectorBitmap:TBytes):Boolean;
function CountSetBits(const Bitmap:TBytes):UInt64;
function CountBitmapBits(const Bitmap:TBytes;ValidBits:UInt32):UInt32;
function GetExt4UsedBlockCount(const Device:string;const Info:TExt4Info;var UsedBlocks:UInt64):Boolean;

implementation

uses
  BaseUnix,Unix;

function ReadLE16(const B:TBytes;Offset:Integer):UInt16;
begin
  Result:=UInt16(B[Offset]) or (UInt16(B[Offset+1]) shl 8);
end;

function ReadLE32(const B:TBytes;Offset:Integer):UInt32;
begin
  Result:=UInt32(B[Offset]) or (UInt32(B[Offset+1]) shl 8) or (UInt32(B[Offset+2]) shl 16) or (UInt32(B[Offset+3]) shl 24);
end;

function ReadAt(const Device:string;Offset:Int64;Buffer:Pointer;Count:Integer):Boolean;
var
  F:TFileStream;
begin
  Result:=False;
  try
    F:=TFileStream.Create(Device,fmOpenRead or fmShareDenyNone);
    try
      if F.Seek(Offset,soBeginning)<>Offset then Exit;
      if F.Read(Buffer^,Count)<>Count then Exit;
      Result:=True;
    finally
      F.Free;
    end;
  except
    Result:=False;
  end;
end;

function ReadExt4Info(const Device:string;var Info:TExt4Info):Boolean;
const
  SUPERBLOCK_OFFSET=1024;
  SUPERBLOCK_SIZE=1024;
  EXT4_MAGIC_OFFSET=$38;
  EXT4_LOG_BLOCK_SIZE=$18;
  EXT4_BLOCKS_COUNT_LO=$04;
  EXT4_BLOCKS_PER_GROUP=$20;
  EXT4_FIRST_DATA_BLOCK=$14;
  EXT4_FEATURE_INCOMPAT=$60;
  EXT4_DESC_SIZE=$FE;
  EXT4_FEATURE_INCOMPAT_64BIT=$80;
var
  B:TBytes;
  Magic:UInt16;
  LogBlockSize,FeaturesIncompat,BlocksLo,BlocksHi:UInt32;
  DataBlocks:UInt64;
begin
  Result:=False;
  FillChar(Info,SizeOf(Info),0);
  SetLength(B,SUPERBLOCK_SIZE);
  if not ReadAt(Device,SUPERBLOCK_OFFSET,@B[0],Length(B)) then Exit;
  Magic:=ReadLE16(B,EXT4_MAGIC_OFFSET);
  if Magic<>$EF53 then Exit;
  LogBlockSize:=ReadLE32(B,EXT4_LOG_BLOCK_SIZE);
  if LogBlockSize>6 then Exit;
  Info.BlockSize:=UInt32(1024) shl LogBlockSize;
  BlocksLo:=ReadLE32(B,EXT4_BLOCKS_COUNT_LO);
  FeaturesIncompat:=ReadLE32(B,EXT4_FEATURE_INCOMPAT);
  Info.Is64Bit:=(FeaturesIncompat and EXT4_FEATURE_INCOMPAT_64BIT)<>0;
  if Info.Is64Bit then begin
    BlocksHi:=ReadLE32(B,$150);
    Info.BlockCount:=UInt64(BlocksLo) or (UInt64(BlocksHi) shl 32);
  end else Info.BlockCount:=BlocksLo;
  Info.BlocksPerGroup:=ReadLE32(B,EXT4_BLOCKS_PER_GROUP);
  Info.FirstDataBlock:=ReadLE32(B,EXT4_FIRST_DATA_BLOCK);
  if Info.Is64Bit then Info.DescSize:=ReadLE16(B,EXT4_DESC_SIZE) else Info.DescSize:=32;
  if Info.DescSize<32 then Info.DescSize:=32;
  if (Info.BlocksPerGroup=0) or (Info.BlockCount<=Info.FirstDataBlock) then Exit;
  DataBlocks:=Info.BlockCount-Info.FirstDataBlock;
  Info.GroupCount:=UInt32((DataBlocks+Info.BlocksPerGroup-1) div Info.BlocksPerGroup);
  Result:=True;
end;

function ReadExt4BlockBitmap(const Device:string;const Info:TExt4Info;Group:UInt32;var Bitmap:TBytes):Boolean;
var
  GroupDescBlock,GroupDescOffset,BitmapBlock:UInt64;
  Descriptor:TBytes;
  BitmapBlockLo,BitmapBlockHi:UInt32;
begin
  Result:=False;
  if Group>=Info.GroupCount then Exit;
  SetLength(Bitmap,Info.BlockSize);
  SetLength(Descriptor,Info.DescSize);
  if Info.BlockSize=1024 then GroupDescBlock:=2 else GroupDescBlock:=1;
  GroupDescOffset:=GroupDescBlock*UInt64(Info.BlockSize)+UInt64(Group)*UInt64(Info.DescSize);
  if not ReadAt(Device,Int64(GroupDescOffset),@Descriptor[0],Length(Descriptor)) then Exit;
  BitmapBlockLo:=ReadLE32(Descriptor,0);
  if Info.Is64Bit then BitmapBlockHi:=ReadLE32(Descriptor,$20) else BitmapBlockHi:=0;
  BitmapBlock:=UInt64(BitmapBlockLo) or (UInt64(BitmapBlockHi) shl 32);
  if BitmapBlock=0 then Exit;
  if not ReadAt(Device,Int64(BitmapBlock*UInt64(Info.BlockSize)),@Bitmap[0],Info.BlockSize) then Exit;
  Result:=True;
end;

function GetSectorSize(const Device:string):UInt32;
const
  BLKSSZGET=$1268;
var
  FD,Size:Integer;
begin
  Result:=0;
  FD:=fpOpen(PChar(Device),O_RDONLY);
  if FD<0 then Exit;
  try
    Size:=0;
    if fpIOCtl(FD,BLKSSZGET,@Size)=0 then Result:=Size;
  finally
    fpClose(FD);
  end;
end;

procedure SetBit(var Bitmap:TBytes;BitIndex:UInt64);inline;
begin
  Bitmap[BitIndex shr 3]:=Bitmap[BitIndex shr 3] or Byte(1 shl (BitIndex and 7));
end;

function BuildUsedSectorBitmap(const Device:string;const Info:TExt4Info;var SectorBitmap:TBytes):Boolean;
var
  Group,BlockInGroup,BlocksInGroup,SectorOffset:UInt32;
  BlockNumber,SectorNumber,TotalSectors:UInt64;
  SectorSize,SectorsPerBlock:UInt32;
  Bitmap:TBytes;
begin
  Result:=False;
  SectorSize:=GetSectorSize(Device);
  if SectorSize=0 then Exit;
  if (Info.BlockSize mod SectorSize)<>0 then Exit;
  SectorsPerBlock:=Info.BlockSize div SectorSize;
  TotalSectors:=Info.BlockCount*UInt64(SectorsPerBlock);
  SetLength(SectorBitmap,(TotalSectors+7) div 8);
  if Length(SectorBitmap)>0 then FillChar(SectorBitmap[0],Length(SectorBitmap),0);
  for Group:=0 to Info.GroupCount-1 do begin
    if not ReadExt4BlockBitmap(Device,Info,Group,Bitmap) then Exit;
    BlocksInGroup:=Info.BlocksPerGroup;
    if Group=Info.GroupCount-1 then BlocksInGroup:=UInt32(Info.BlockCount-Info.FirstDataBlock)-Group*Info.BlocksPerGroup;
    for BlockInGroup:=0 to BlocksInGroup-1 do begin
      if (Bitmap[BlockInGroup shr 3] and Byte(1 shl (BlockInGroup and 7)))<>0 then begin
        BlockNumber:=UInt64(Info.FirstDataBlock)+UInt64(Group)*UInt64(Info.BlocksPerGroup)+BlockInGroup;
        if BlockNumber>=Info.BlockCount then Continue;
        SectorNumber:=BlockNumber*UInt64(SectorsPerBlock);
        for SectorOffset:=0 to SectorsPerBlock-1 do SetBit(SectorBitmap,SectorNumber+SectorOffset);
      end;
    end;
  end;
  Result:=True;
end;

function CountSetBits(const Bitmap:TBytes):UInt64;inline;
var
  I:Integer;
  B:Byte;
begin
  Result:=0;
  for I:=0 to High(Bitmap) do begin
    B:=Bitmap[I];
    while B<>0 do begin
      B:=B and (B-1);
      Inc(Result);
    end;
  end;
end;

function CountBitmapBits(const Bitmap:TBytes;ValidBits:UInt32):UInt32;
var
  I,MaxBits:UInt32;
  B:Byte;
begin
  Result:=0;
  MaxBits:=UInt32(Length(Bitmap)*8);
  if ValidBits<MaxBits then MaxBits:=ValidBits;
  for I:=0 to (MaxBits div 8)-1 do begin
    B:=Bitmap[I];
    while B<>0 do begin
      B:=B and (B-1);
      Inc(Result);
    end;
  end;
  I:=(MaxBits div 8)*8;
  while I<MaxBits do begin
    if (Bitmap[I shr 3] and Byte(1 shl (I and 7)))<>0 then Inc(Result);
    Inc(I);
  end;
end;

function GetExt4UsedBlockCount(const Device:string;const Info:TExt4Info;var UsedBlocks:UInt64):Boolean;
var
  Group,BlocksInGroup:UInt32;
  Bitmap:TBytes;
begin
  Result:=False;
  UsedBlocks:=0;
  for Group:=0 to Info.GroupCount-1 do begin
    if not ReadExt4BlockBitmap(Device,Info,Group,Bitmap) then Exit;
    BlocksInGroup:=Info.BlocksPerGroup;
    if Group=Info.GroupCount-1 then BlocksInGroup:=UInt32(Info.BlockCount-Info.FirstDataBlock)-Group*Info.BlocksPerGroup;
    UsedBlocks:=UsedBlocks+CountBitmapBits(Bitmap,BlocksInGroup);
  end;
  Result:=True;
end;

end.

