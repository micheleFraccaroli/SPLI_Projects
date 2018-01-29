close all;
clear all;
clc;

% Chunk 4 bytes
fileName='tux.jpg';
lengthChunk=4;
modulo = double(2^32);
host = '192.168.43.143';
port = 8081;
% key = 7;

primesFileID=fopen('prime.txt','r');
primes=textscan(primesFileID,'%d\t%d');
primes=primes{1,2};
% primes=uint64(primes(2:end)');
primes=double(primes(2:end)');


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
fclose(fileIDImage);
% Costruzione dell'ultimo chunk con i byte mancanti a zero
tmpBin=dec2bin(tmp,8);
for ii=remainingBytes+1:lengthChunk
    tmpBin(ii,:)='00000000';
end
lastBits='';
for ii=flip(1:size(tmpBin,1))
    lastBits=[lastBits tmpBin(ii,:)];
end
lastChunk=bin2dec(lastBits);
uint32Stream=[uint32Stream' lastChunk];

% Padding con il numero di bytes a zero messi
padding=uint64(lengthChunk-remainingBytes);
uint32Stream=uint64([uint32Stream padding]);
nChunk=length(uint32Stream);

% Selecting the keys
currKeys=datasample(primes,nChunk);

% START euclidian-algorithm
% Calcolo degli inversi moltiplicativi delle chiavi selezionate
tic;
currDecrKeys=zeros(1,nChunk,'double');
for ii=1:nChunk
    [x, y] = eea(modulo,currKeys(ii)); % key ----> currkeys(ii)
    if (x < 0)
        currDecrKeys(ii) = modulo + x; % dkey ----> currDecrKeys(ii)
    else
        currDecrKeys(ii) = x; % dkey ----> currDecrKeys(ii)
    end
end
toc;
% load('currKeysS','currKeysS');
% load('currDecrKeysS','currDecrKeysS');
% load('currKeysR','currKeysR');
% load('currDecrKeysR','currDecrKeysR');
% currKeys=currKeysS;
% currDecrKeys=currDecrKeysS;


% % CRIPTO LA PRIMA VOLTA
cryptedChunkStream=mod((uint32Stream.*uint64(currKeys)),uint64(modulo)); % (uint32Stream.*uint64(currKeys)
% test=mod((cryptedChunkStream.*uint64(currDecrKeys)),uint64(modulo));

cryptedChunkStream=uint32(cryptedChunkStream);

% INVIO
tcp_com = tcpip(host, port, 'NetworkRole' ,'client','Timeout', 120);
fopen(tcp_com);
fwrite(tcp_com, nChunk, 'uint32');
fprintf('\nN. chunk -----> %d\t Inviato ...', nChunk);
fprintf('\nFase 1 invio immagine criptata: ');
% fprintf('reset\r');
for ii=1:nChunk
    fwrite(tcp_com, cryptedChunkStream(ii), 'uint32');
    % fprintf('%d/%d chunk\r',[ii, nChunk]);
end
% fprintf('reset\r');
fprintf('\nInvio completato ...');

% RICEZIONE
fprintf('\nFase 2 ricezione file criptato: ');
fprintf('reset\r');
ret=zeros(1,nChunk, 'uint32');
% pause(5);
for ii=1:nChunk
    ret(ii)=fread(tcp_com,1,'uint32');
    % fprintf('%d/%d chunk\r',[ii, nChunk]);
end
% fprintf('reset\r');
fprintf('\nRicezione completata ...');
ret=uint64(ret);

% check=mod((ret.*uint64(currDecrKeys)),uint64(modulo));
% check=mod((check.*uint64(currDecrKeysR)),uint64(modulo));
% errAfter2EncryptS=sum(check-uint64(check));

% DECRIPTO
decryptedChunkStream=mod((ret.*uint64(currDecrKeys)),uint64(modulo)); % (ret.*uint64(currDecrKeys)

% REINVIO
fprintf('\nFase 3 invio file decriptato: ');
fprintf('reset\r');
decryptedChunkStream=uint32(decryptedChunkStream);
for ii=1:nChunk
    fwrite(tcp_com, decryptedChunkStream(ii), 'uint32');
    % fprintf('%d/%d chunk\r',[ii, nChunk]);
end
%fprintf('reset\r');
fprintf('\nFINE\n\n');

fclose(tcp_com);
delete(tcp_com);
clear t;


