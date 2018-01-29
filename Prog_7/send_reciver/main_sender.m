close all;
clear all;
clc;

% Chunk 4 bytes
fileName='tux.jpg';
[imageName,format] = strtok(fileName, '.');
format=format(2:end);
lengthChunk=4;
modulo = (2^32);
host = '192.168.43.143';
port = 8082;

key = 7;


fprintf('\n----------------------SENDER----------------------\n');
% charKey=dec2bin(key,8);
fprintf('\nStart crypt....\n');
fileIDImage=fopen(fileName);
fileStats=dir(fileName);
nBytes=fileStats.bytes;
% ULTIMO BYTE CHE LEGGE DIVENTA IL PIU' SIGNIFICATIVO PER IL uint32
[uint32Stream, count]=fread(fileIDImage,'uint32');
% Numero di byte rimasti fuori dalla lettura a 4 alla volta
remainingBytes=nBytes-count*4;
fseek(fileIDImage,count*4,'bof');
tmp=fread(fileIDImage,remainingBytes,'uint8');
% Costruzione dell'ultimo chunk con i byte mancanti a zero
tmpBin=dec2bin(tmp);
for ii=remainingBytes+1:lengthChunk
    tmpBin(ii,:)='00000000';
end
lastBits='';
for ii=flip(1:size(tmpBin,1))
    lastBits=[lastBits tmpBin(ii,:)];
end
lastChunk=bin2dec(lastBits);
uint32Stream=[uint32Stream' lastChunk];
fclose(fileIDImage);
% Padding con il numero di bytes a zero messi
padding=uint32(lengthChunk-remainingBytes);
uint32Stream=double([uint32Stream padding]);
nChunk=length(uint32Stream);

% % Selecting the keys
% currKeys=randi([3 2^32],1,nChunk);
% 
% % I pari li scarto
% ind= mod(currKeys,2)==0;
% currKeys(ind)=currKeys(ind)+1;

% START euclidian-algorithm
% Calcolo degli inversi moltiplicativi delle chiavi selezionate
tic;
%currDecrKeys=zeros(1,nChunk);
for ii=1:nChunk
    [x, y] = eea(modulo, key); %currKeys(ii)
    if (x < 0)
        dkey = modulo + x; %currKeys(ii)
    else
        dkey = x; %currKeys(ii)
    end
%     [d, q, a, b, f] = extendedEuclidean_forward(modulo,currKeys(ii));
%     [x, y] = extendedEuclidean_backSubstitution (d, q, a, b, f);
%     if (x < 0)
%         currDecrKeys(ii) = modulo + x;
%     else
%         currDecrKeys(ii) = x;
%     end
end
toc;


% % CRIPTO LA PRIMA VOLTA
cryptedChunkStream=mod((uint32Stream*key),modulo); %(uint32Stream.*currKeys)
cryptedChunkStream=uint32(cryptedChunkStream);

% INVIO
tcp_com = tcpip(host, port, 'NetworkRole' ,'client');
fopen(tcp_com);
fwrite(tcp_com, nChunk, 'uint32');
fprintf('\nN. chunk -----> %d\t Inviato ...', nChunk);
fprintf('\nFase 1 invio immagine criptata: \r');
%fprintf_r('reset');
for ii=1:nChunk
    fwrite(tcp_com, cryptedChunkStream(ii), 'uint32');
    %fprintf('%d/%d chunk',[ii, nChunk]);
end
%fprintf_r('reset');
fprintf('\nInvio completato ...');

% RICEZIONE
fprintf('\nFase 2 ricezione file criptato: ');
%fprintf_r('reset');
ret=zeros(1,nChunk, 'uint32');
for ii=1:nChunk
    ret(ii)=fread(tcp_com,1,'uint32');
    %fprintf_r('%d/%d chunk',[ii, nChunk]);
end
%fprintf_r('reset');
fprintf('\nRicezione completata ...');
% DECRIPTO
fprintf('\nDecripto....\n');
ret=double(ret);
decryptedChunkStream=mod((ret*uint64(dkey)),modulo); %ret.*currDecrKeys

% REINVIO
fprintf('\nFase 3 invio file decriptato: ');
%fprintf_r('reset');
decryptedChunkStream=uint32(decryptedChunkStream);
for ii=1:nChunk
    fwrite(tcp_com, decryptedChunkStream(ii), 'uint32');
    %fprintf_r('%d/%d chunk',[ii, nChunk]);
end
%fprintf_r('reset');
fprintf('\nFINE\n\n');


fclose(tcp_com);
delete(tcp_com);
clear t;


