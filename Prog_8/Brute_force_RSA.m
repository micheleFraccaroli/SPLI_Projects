% scelta chiavi e primi
% e = ...;
% p = ...;
% q = ...;
% n = (p*q);
% fiN = (p-1)*(q-1);

flag = true;
d = 3;
tic;
fprintf('\n****************Decrypting Brute Force RSA********************\n');

while(1)
    for i=1:len
        decrypt(i) = modExp(crypt(i), d, n);
    end
    
    decryptFileName = ('decrypt_RSA_image.jpg');
    fileIDDecryptImage = fopen(decryptFileName,'w');
    fwrite(fileIDDecryptImage, decrypt);
    fclose(fileIDDecryptImage);
    
    try
        pic = imread(decryptFileName);
        timeElapsed=toc;
        fprintf(' -------> DECRYPTED');
        fprintf('\n****************End Brute Force RSA***************************');
        fprintf('\n\n\n');
        fprintf('\nKey value find: %d',d);
        fprintf('\nTime spent for decrypt RSA: %.3f s',timeElapsed);
        fprintf('\n********************FINISH********************************\n')
        image(pic)
        break;
    catch ME
        fprintf(' -------> Brute force RSA failed\n');
        d = d + 2;
    end
    
end

