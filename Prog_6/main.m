Tclose all;
clear all;
clc;

% Chunk 16 bytes
fileName='test_image.jpg';
[imageName,format] = strtok(fileName, '.');
format=format(2:end);
lengthChunk=16;
lengthKey=8;
key=5;
funType='xor';
cryptType='rngA';
nIt = 8;

% charKey=dec2bin(key,8);
fprintf('\nStart....\n');
fileIDImage=fopen(fileName);
bytesStream=fread(fileIDImage,'uint8');
fclose(fileIDImage);
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

cryptedChunkStream=iterativeCrypt(chunkStream,key,funType, cryptType, nIt);
fprintf('\nImmagine criptata.....\n');
%% Decrypt
fprintf('\n****************Decrypting Brute Force********************');

fileLN = fopen('lorpi_nik_encrypter/test_image_crypt.bin');
% [imageName,format] = strtok(fileLN, '.');
% format=format(2:end);
cryptType='rngNO';
nIt = 8;
funType='xor';
lengthChunk=16;
lengthKey=8;
bytesStreamLN = fread(fileLN, 'uint8');
fclose(fileLN);
nChunk=floor(length(bytesStreamLN)/lengthChunk);
cryptedChunkStream=reshape(bytesStreamLN(1:nChunk*lengthChunk),[lengthChunk nChunk]);

tic;
for j=0:(2^lengthKey-1)
    fprintf('\nTrying key value: %d',j);
    decryptedChunkStream=iterativeDecrypt(cryptedChunkStream,j,funType, cryptType, nIt);

    decryptedBytesStream=reshape(decryptedChunkStream(:,1:end-2),[size(decryptedChunkStream(:,1:end-2),2)*lengthChunk 1]);
    nPad=decryptedChunkStream(end,end);
    decryptedBytesStream=[decryptedBytesStream ; decryptedChunkStream(1:end-nPad,end-1)];
    decryptFileName=('decrypt_image.jpg');
    fileIDDecryptImage=fopen(decryptFileName,'w');
    fwrite(fileIDDecryptImage,decryptedBytesStream);
    fclose(fileIDDecryptImage);
    try
        RGB=imread(decryptFileName);
        timeElapsed=toc;
        fprintf(' -------> DECRYPTED');
        fprintf('\n****************End Brute Force***************************');
        fprintf('\n\n\n');
        fprintf('\nCorrect key value find is %d',j);
        fprintf('\nTime spent for decrypt the image: %.3f s',timeElapsed);
        fprintf('\n********************FINISH********************************\n')
        image(RGB)
        break;
    catch ME
        fprintf(' -------> Decrypt failed\n');
    end
end
