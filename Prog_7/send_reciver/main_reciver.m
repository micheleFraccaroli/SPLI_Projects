close all;
clear all;
clc;

% Chunk 4 bytes
fileName='decrypt.jpg';
[imageName,format] = strtok(fileName, '.');
format=format(2:end);
lengthChunk=4;
modulo = (2^32);
host = 'localhost';
port = 8081;


fprintf('\n----------------------RECIVER----------------------\n');


fprintf('\nStart crypt....\n');



% RICEZIONE
tcp_com = tcpip(host, port, 'NetworkRole' ,'server');
fopen(tcp_com);
nChunk=fread(tcp_com,1,'uint32');
fprintf('\nN. chunk -----> %d\t Ricevuto ...', nChunk);
ret=zeros(1,nChunk, 'uint32');
fprintf('\nFase 1 ricezione immagine criptata: ');
%fprintf_r('reset');
for ii=1:nChunk
    ret(ii)=fread(tcp_com, 1, 'uint32');
    %fprintf_r('%d/%d chunk',[ii, nChunk]);
end
%fprintf_r('reset');
ret=double(ret);
fprintf('\nRicezione completata ...');

% % CRIPTO LA PRIMA VOLTA
% Selecting the keys
currKeys=randi([3 2^32],1,nChunk);
% I pari li scarto
ind= mod(currKeys,2)==0;
currKeys(ind)=currKeys(ind)+1;
% START euclidian-algorithm
% Calcolo degli inversi moltiplicativi delle chiavi selezionate
currDecrKeys=zeros(1,nChunk);
for ii=1:nChunk
    [d, q, a, b, f] = extendedEuclidean_forward(modulo,currKeys(ii));
    [x, y] = extendedEuclidean_backSubstitution (d, q, a, b, f);
    if (x < 0)
        currDecrKeys(ii) = modulo + x;
    else
        currDecrKeys(ii) = x;
    end
end
cryptedChunkStream=mod((ret.*currKeys),modulo);
cryptedChunkStream=uint32(cryptedChunkStream);

% INVIO
fprintf('\nFase 2 invio file criptato: ');
%fprintf_r('reset');
for ii=1:nChunk
    fwrite(tcp_com, cryptedChunkStream(ii), 'uint32');
    %fprintf_r('%d/%d chunk',[ii, nChunk]);
end
%fprintf_r('reset');
fprintf('\nInvio completato ...');




% RICEVO PER ULTIMA VOLTA
fprintf('\nFase 3 ricevo file decriptato: ');
%fprintf_r('reset');
cryptedChunkStream=zeros(1,nChunk,'uint32');
for ii=1:nChunk
    cryptedChunkStream(ii)=fread(tcp_com, 1, 'uint32');
    %fprintf_r('%d/%d chunk',[ii, nChunk]);
end
%fprintf_r('reset');
fprintf('\nRicezione completata ...');
fclose(tcp_com);
delete(tcp_com);
clear t;

cryptedChunkStream=double(cryptedChunkStream);
% DECRIPTO
decryptedChunkStream=mod((ret.*currDecrKeys),modulo);


bitsStream=dec2bin(decryptedChunkStream);
tmp8=zeros(size(bitsStream,1),lengthChunk);

for jj=1:lengthChunk
    tmp8(:,jj)=bin2dec(bitsStream(:,(jj-1)*8+1:(jj-1)*8+8));
end
% QUESTA ULTIMA PARTE � DA SISTEMARE
tmp8=flip(tmp8,2)';

% tmp8=tmp8(:)';
% tmp8=[tmp8 tmp'];
% IDDecrypt=fopen(fileName,'w');
% fwrite(IDDecrypt,tmp8);
% fclose(IDDecrypt);
% im=imread(fileName);
% image(im)






fprintf('\nFINEn\n');





