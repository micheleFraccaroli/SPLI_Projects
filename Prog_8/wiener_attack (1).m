clear all;
close all;
clc;

clear all;
close all;
clc
nWorker=4;

fileName='baboon.jpg';
nBitsPrimesPQ=8;
nBitsPrimesN=2*nBitsPrimesPQ;
lengthChunk=nBitsPrimesPQ/8;
switch nBitsPrimesPQ
    case 8
        dataReadType='uint8';
    otherwise
        error('Error: prime numbers to long to perform bruteforce');
end

% scelta chiavi e primi
% primeNumbersPQ=primes(2^nBitsPrimesPQ);
% ind=primeNumbersPQ>70*lengthChunk;
% p=0;q=0; cont=0;
% while p==q && cont<1000
%     tmp=datasample(primeNumbersPQ(ind),2);
%     p=tmp(1);
%     q=tmp(2);
%     cont=cont+1;
% end
% if cont>1000
%     error('ERRORE')
% end
p = 163;
q = 239;
n = (p*q);
phiN = (p-1)*(q-1);
primeNumbers=primes(phiN);
maxPQ=max([p q]);
ind=(primeNumbers>maxPQ);
d=5;

% e=37;

[x, y] = eea(double(phiN),double(d));
if (x < 0)
    e = phiN + x;
else
    e = x;
end
fprintf('\nTwo prime numbers p=%d, q=%d ---> n=%d, phi(n)=%d',p,q,n,phiN);
fprintf('\nPublic key e=%d',e);
fprintf('\nPrivate key d=%d',d);

fileIDImage=fopen(fileName);
[imageName,format] = strtok(fileName, '.');
format=format(2:end);

[uintStream, count]=fread(fileIDImage,dataReadType);

uintStream=uint16(uintStream)';






tic;
crypt=zeros(1,length(uintStream),'uint64');
for ii=1:length(uintStream)
    crypt(ii)=modExp(uintStream(ii),e,n);
end
timeCrypt=toc;
% disp(['Elapsed time for crypt: ' num2str(timeCrypt)]);

crypt=uint16(crypt);

%% 
decrypt = [];


c = [];
den = [];
a = cont_fraction(e,n);

den(1) = 1;
den(2) = a(2);

for i=3:length(a)
    den(i) = ((a(i)*den(i-1))+den(i-2));
end

fprintf('\n---------- Start Wiener attack ----------\n');
for i=1:length(den)
    for j=1:length(crypt)
        decrypt(j) = modExp(crypt(j), den(i), n);
    end
    
    decryptFileName = ('decrypt_WA-RSA_image.jpg');
    fileIDDecryptImage = fopen(decryptFileName,'w');
    fwrite(fileIDDecryptImage, decrypt);
    fclose(fileIDDecryptImage);
    
    try
        pic = imread(decryptFileName);
        timeElapsed=toc;
        fprintf(' -------> DECRYPTED');
        fprintf('\n---------- End Wiener attack ----------\n');
        fprintf('\n\n\n');
        fprintf('\nKey value find: %d',d);
        fprintf('\nTime spent for decrypt RSA with Wiener attack: %.3f s',timeElapsed);
        fprintf('\n---------- FINISH ----------n')
        image(pic)
        break;
    catch ME
        fprintf(' -------> Wiener attack failed\n');
    end
end
