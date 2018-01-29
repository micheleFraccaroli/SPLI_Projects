function encrypt = iterativeCrypt( chunkStream, key ,funType, cryptType, varargin)

if strcmp('rng', cryptType)
    rng(key)
    currNumbers = randi(256, [1 varargin{1}])-1;
    cryptedChunkStream=zeros(size(chunkStream));
    for j=1:length(currNumbers)
        for i=1:size(chunkStream,2)
            cryptedChunkStream(1:end/2,i)=chunkStream(end/2+1:end,i);
            tmp=encryptFun(chunkStream(end/2+1:end,i),currNumbers(j), funType);
            cryptedChunkStream(end/2+1:end,i)=bitxor(chunkStream(1:end/2,i),tmp,'uint8');
        end
        chunkStream=cryptedChunkStream;
    end
else
    for j=0:7
        binKey=dec2bin(key,8);
        currKey=circshift(binKey,j);
        currKey=bin2dec(currKey);
        cryptedChunkStream=zeros(size(chunkStream));
        for i=1:size(chunkStream,2)
            cryptedChunkStream(1:end/2,i)=chunkStream(end/2+1:end,i);
            tmp=encryptFun(chunkStream(end/2+1:end,i),currKey, funType);
            cryptedChunkStream(end/2+1:end,i)=bitxor(chunkStream(1:end/2,i),tmp,'uint8');
        end
        
        chunkStream=cryptedChunkStream;
    end
end
encrypt=chunkStream;
end

