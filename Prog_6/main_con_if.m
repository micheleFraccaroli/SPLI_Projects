close all;
clear all;
clc;

% Chunk 16 bytes
lengthChunk=16;
key=17;
charKey=dec2bin(key,8);

fileIDImage=fopen('test.bin');
bytesStream=fread(fileIDImage,'uint8');
nChunk=floor(length(bytesStream)/lengthChunk);
chunkStream=reshape(bytesStream(1:nChunk*lengthChunk),[lengthChunk nChunk]);
% bitsStream=dec2bin(bytesStream);
remainingBytes=length(bytesStream)-nChunk*lengthChunk;
if remainingBytes > 0
    paddingBytes=zeros(1,lengthChunk-remainingBytes);
    chunkStream=[chunkStream zeros(lengthChunk,2)];
    chunkStream(:,end-1)=[bytesStream(end-remainingBytes+1:end); paddingBytes'];
    chunkStream(end,end)=lengthChunk-remainingBytes;
else
    chunkStream=([chunkStream zeros(lengthChunk,1)]);
end

cryptedChunkStream=zeros(size(chunkStream));
for i=1:size(chunkStream,2)
    
    cryptedChunkStream(1:end/2,i)=chunkStream(end/2+1:end,i);
    tmp=bitxor(chunkStream(end/2+1:end,i),key,'uint8');
    cryptedChunkStream(end/2+1:end,i)=bitxor(chunkStream(1:end/2,i),tmp,'uint8');    
end
%% decription
decryptedChunkStream=zeros(size(chunkStream));
for i=1:size(chunkStream,2)
    
    tmp=bitxor(cryptedChunkStream(1:end/2,i),key,'uint8');
    decryptedChunkStream(1:end/2,i)=bitxor(cryptedChunkStream(end/2+1:end,i),tmp,'uint8');   
    decryptedChunkStream(end/2+1:end,i)=cryptedChunkStream(1:end/2,i);   
end

