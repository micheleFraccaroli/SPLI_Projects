clear all;
close all;
clc;

crypt = [];
decrypt = [];

e = 13;
n = 29;
c = [];
den = []
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
    
    fprintf('\nTest with decryption-key d = %d\n', den(i));
    
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
        fprintf('\nKey value find: %d',den(i));
        fprintf('\nTime spent for decrypt RSA with Wiener attack: %.3f s',timeElapsed);
        fprintf('\n---------- FINISH ----------n')
        image(pic)
        break;
    catch ME
        fprintf(' -------> Wiener attack failed\n');
    end
end
