function decrypt = iterativeDecrypt( cryptedChunkStream,key,funType, cryptType, varargin)
shifts=flip((0:7));
if strcmp('rng', cryptType)
    rng(key);
    currNumbers = randi(256,[1 varargin{1}])-1;
    currNumbers = flip(currNumbers);
    decryptedChunkStream=zeros(size(cryptedChunkStream));
    for j=1:length(currNumbers)
        for i=1:size(cryptedChunkStream,2)
            tmp=encryptFun(cryptedChunkStream(1:end/2,i),currNumbers(j),funType);
            decryptedChunkStream(1:end/2,i)=bitxor(cryptedChunkStream(end/2+1:end,i),tmp,'uint8');
            decryptedChunkStream(end/2+1:end,i)=cryptedChunkStream(1:end/2,i);
        end
        cryptedChunkStream=decryptedChunkStream;
    end
else
    for j=1:8
        binKey=dec2bin(key,8);
        currKey=circshift(binKey,shifts(j));
        currKey=bin2dec(currKey);
        decryptedChunkStream=zeros(size(cryptedChunkStream));
        for i=1:size(cryptedChunkStream,2)
            tmp=encryptFun(cryptedChunkStream(1:end/2,i),currKey,funType);
            decryptedChunkStream(1:end/2,i)=bitxor(cryptedChunkStream(end/2+1:end,i),tmp,'uint8');
            decryptedChunkStream(end/2+1:end,i)=cryptedChunkStream(1:end/2,i);
        end
        cryptedChunkStream=decryptedChunkStream;
    end
end
    decrypt=cryptedChunkStream;
end

