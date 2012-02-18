%% Size: 32
-record(superblock, {node,
                     zone,
                     node_blocks,
                     zone_blocks,
                     first_data_zone,
                     zone_size,
                     file_max_size,
                     magic,
                     state,
                     
                     zones,
                     magic_v3,
                     blocksize,
                     disk_version,
                     res0,
                     ng_uuid,
                     ng_label,
                     ng_flags,
                     ng_magic}).
        
%% Size: 64
-record(inode_v2, {mode,
                   links,
                   uid,
                   gid,
                   size,
                   atime,
                   mtime,
                   ctime,
                   zone}).
        

-record(disk_info, {superblock = #superblock{},
                    inodes_map = #inode_v2{},
                    inodes = []}).

%% Pierwsze bloki po 1024:
%% 0 -> MBR??
%% 1 -> SUPER-BLOCK

%% Nastepne po 2048 liczone od poczatku (2048 - wedle block size w superblock):
%% 4 -> INode List (modyfikacja pliku, uprawnienia, wielkosc itd)
%%      (ma 8 blokow - skad sie to bierze?)

%% 12 -> kolejne 8 blokow jest pustych

%% 20 -> Pierwsze dane (nodeId + nazwy katalogow i plikow) = 32bit
%%       (w superblock zapisane jest ze first_data_zone - to wlasnie ten blok)
%%       (te dane sa w 14 blokach - potem zaczynaja sie pliki)
