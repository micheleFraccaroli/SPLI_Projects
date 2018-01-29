clear all;
close all;
clc;

fileName='baboon.jpg';

p = uint64(266122159);
q = uint64(229192867);
n = uint64(p*q);
phiN = uint64((p-1)*(q-1));
d=uint64(64139);
e=uint64(55672707104018147);

fprintf('\nTwo prime numbers p=%d, q=%d ---> n=%d, phi(n)=%d',p,q,n,phiN);
fprintf('\nPublic key e=%d',e);
fprintf('\nPrivate key d=%d',d);

fileIDImage=fopen(fileName);
[imageName,format] = strtok(fileName, '.');
format=format(2:end);

[uintStream, count]=fread(fileIDImage,'uint8');
uintStream=uintStream';

tic;
crypt=zeros(1,length(uintStream),'uint64');
for ii=1:length(uintStream)
    crypt(ii)=modExp(uint64(uintStream(ii)),uint64(e),uint64(n));
end
timeCrypt=toc;

%% 
decrypt = [];
decrypt=uint64(decrypt);

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
        decrypt(j) = modExp(crypt(j),uint64(den(i)),uint64(n));
    end
    
    tmp8=uint8(decrypt);  
    decryptFileName = ('decrypt_WA-RSA_image.jpg');
    fileIDDecryptImage = fopen(decryptFileName,'w');
    fwrite(fileIDDecryptImage, tmp8);
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
