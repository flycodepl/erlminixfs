-module(main).
-include("minix.hrl").

-define(SUPER_MAGIC, 5023). %% DEC: 5023
-define(SUPER_MAGIC_25, 14561). %% DEC: 14561

-export([read/0,
         read/1]).


read() ->
    read("./priv/part_minixfs1.img").

read(File) ->
    %% {ok, F} = file:open("./priv/aaa.img", [read, binary]),
    {ok, F} = file:open(File, [read, binary]),
    SuperBlockBin = readFromBlock(F, 1, 32, 1024),
    SB = readSuperBlock(SuperBlockBin),
    
    InodesBitMapBin = readBlock(F, 4, 8),
    InodesMap = parseInodesBitMap(InodesBitMapBin),
    %% _ZoneBitMapBin = readBlock(F, 16, 8*2048),

    InodesBin = readBlock(F, SB#superblock.first_data_zone, 14),
    Inodes = parseInodesZone(InodesBin, SB#superblock.blocksize),

    Info = #disk_info{superblock = SB, inodes_map = InodesMap, inodes = Inodes},
    
    printProto(Info).

    

printProto(#disk_info{superblock = SB}) ->
    io:fwrite("# minix fs description~n"
              "boot description (ignored)~n"
              "#number of blocks  number of inodes~n"
              "\t~b \t\t ~b~n"
              "# root dir perm~n", [SB#superblock.zone, SB#superblock.node]).



readBlock(FId, BlockNumber, CountBlock) ->
    readBlock(FId, BlockNumber, CountBlock, 2048).
readBlock(FId, BlockNumber, CountBlock, BlockSize) ->
    readFromBlock(FId, BlockNumber, CountBlock*BlockSize, BlockSize).


readFromBlock(FId, BlockNumber, Count) ->
    readFromBlock(FId, BlockNumber, Count, 2048).
readFromBlock(FId, BlockNumber, Count, BlockSize) ->
    BN = BlockNumber * BlockSize,
    {ok, D} = file:pread(FId, BN, Count),
    D.

parseInodesZone(Bin, BlockSize) ->
    parseInodesZone(Bin, BlockSize, []).

parseInodesZone(<<>>, _BlockSize, Acc) ->
    lists:reverse(Acc);
parseInodesZone(Bin, BlockSize, Acc) ->
    <<Zone:BlockSize/binary, Rest/binary>> = Bin,
    FileLists = parseInodes(Zone),
    NewAcc = [FileLists | Acc],
    parseInodesZone(Rest, BlockSize, NewAcc).

parseInodes(Bin) ->
    parseInodes(Bin, []).
parseInodes(<<>>, Acc) ->
    lists:reverse(Acc);
parseInodes(<<0:16/little, _:30/binary, Rest/binary>>, Acc) ->
    parseInodes(Rest, Acc);
parseInodes(<<InodeID:16/little, Name:30/binary, Rest/binary>>, Acc) ->
    File = {InodeID, binary:replace(Name, <<0>>, <<>>, [global])},
    NewAcc = [File | Acc],
    parseInodes(Rest, NewAcc).


parseInodesBitMap(Bin) ->
    parseInodesBitMap(Bin, []).

parseInodesBitMap(<<>>, Acc) ->
    lists:reverse(Acc);
parseInodesBitMap(<<Mode:16/little, Links:16/little, UId:16/little, GId:16/little,
                    Size:32/little, ATime:32/little, MTime:32/little, CTime:32/little,
                    Zone:40/binary, Rest/binary>>, Acc) ->

    Inode = #inode_v2{mode = Mode,
                      links = Links,
                      uid = UId,
                      gid = GId,
                      size = Size,
                      atime = ATime,
                      mtime = MTime,
                      ctime = CTime,
                      zone = Zone},
    NewAcc = [Inode | Acc],
    parseInodesBitMap(Rest, NewAcc).


%% struct minix2_inode {
%% 	__u16 i_mode;
%% 	__u16 i_nlinks;
%% 	__u16 i_uid;
%% 	__u16 i_gid;
%% 	__u32 i_size;
%% 	__u32 i_atime;
%% 	__u32 i_mtime;
%% 	__u32 i_ctime;
%% 	__u32 i_zone[10];
%% };






readSuperBlock(<<Node:16/little, Zone:16/little, NodeMap:16/little, ZoneMap:16/little,
                 FirstDataZone:16/little, ZoneSize:16/little, MaxFileSize:32/little,
                 ?SUPER_MAGIC:16/little, State:16/little, _Rest/binary>>) ->

    #superblock{node = Node,
                zone = Zone,
                node_blocks = NodeMap,
                zone_blocks = ZoneMap,
                first_data_zone = FirstDataZone,
                zone_size = ZoneSize,
                file_max_size = MaxFileSize,
                magic = ?SUPER_MAGIC,
                state = State,
                disk_version = 1};

                

readSuperBlock(<<Node:16/little, _:16/little, NodeMap:16/little, ZoneMap:16/little,
                 FirstDataZone:16/little, ZoneSize:16/little, MaxFileSize:32/little,
                 ?SUPER_MAGIC_25:16/little, State:16/little, 
                 %% FOR version > V1
                 Zone:32/little, _MagicV3:16/little,
                 _:16/little, BlockSize:16/little, _DiskVer:8/little, _Rest/binary>>) ->

    #superblock{node = Node,
                zone = Zone,
                node_blocks = NodeMap,
                zone_blocks = ZoneMap,
                first_data_zone = FirstDataZone,
                zone_size = ZoneSize,
                file_max_size = MaxFileSize,
                magic = ?SUPER_MAGIC_25,
                state = State,
                
                blocksize = BlockSize,
                disk_version = 2.5}.
                


