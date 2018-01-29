% scelta chiavi e primi
clear all;
close all;
clc
nWorker=4;

fileName='Mage.jpg';
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
primeNumbersPQ=primes(2^nBitsPrimesPQ);
ind=primeNumbersPQ>70*lengthChunk;
p=0;q=0; cont=0;
while p==q && cont<1000
    tmp=datasample(primeNumbersPQ(ind),2);
    p=tmp(1);
    q=tmp(2);
    cont=cont+1;
end
if cont>1000
    error('ERRORE')
end
% p = 89;
% q = 31;
n = (p*q);
phiN = (p-1)*(q-1);
primeNumbers=primes(phiN);
maxPQ=max([p q]);
ind=(primeNumbers>maxPQ);
e=datasample(primeNumbers(ind),1);
% e=37;

[x, y] = eea(double(phiN),double(e));
if (x < 0)
    d = phiN + x;
else
    d = x;
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


% for ii=1:length(uintStream)
%     decryptedChunkStream(ii)=modExp(crypt(ii),d,n);
% end
% 
% 
% decryptedChunkStream=uint8(decryptedChunkStream);
% tmp8=decryptedChunkStream;
% 
% decryptFileName=strcat('decrypt_image.',format);
% fileIDDecryptImage=fopen(decryptFileName,'w');
% fwrite(fileIDDecryptImage,tmp8);
% fclose(fileIDDecryptImage);
% RGB=imread(decryptFileName);
% image(RGB);


%%


possDecKey=(3:2:n);
% poolobj=parpool;

fprintf('\n****************Decrypting Brute Force RSA********************\n');
fprintf('\nMax number that will be tested: %d\n',possDecKey(end));
len=length(crypt);

correctKey=0;
tic
spmd(nWorker)
    in=labindex;
    done=0;
    while ~done
        fprintf('Trying key value: %d',possDecKey(in));
        decryptedChunkStream=zeros(1,len);
        for ii=1:len
            decryptedChunkStream(ii) = modExp(crypt(ii), possDecKey(in), n);
        end
        
        decryptFileName=strcat('decrypt_image',num2str(labindex),'.',format);
        fileIDDecryptImage=fopen(decryptFileName,'w');

        fwrite(fileIDDecryptImage,decryptedChunkStream);
        fclose(fileIDDecryptImage);

        try
            RGB=imread(decryptFileName);
            fprintf(' -------> Correctly decrypted\n');
            correctKey=possDecKey(in);
            done=1;
        catch ME
            in=in+nWorker;
%             fprintf('\t%s',ME.identifier);
            try 
                done=gop(@or,done);
            catch
                done=1;
            end
            fprintf(' -------> Decryption failed\n\n');
        end
    end
end
timeElapsed=toc;
fprintf('\n****************End Brute Force***************************');
fprintf('\n\n\n');
correctKey=[correctKey{:}];
ind=correctKey>0;
for j=1:length(ind)
    tmpName=strcat('decrypt_image',num2str(j),'.',format);
    if ind(j)
        newName=strcat('decrypt_image','.',format);
        copyfile(tmpName, newName); 
        RGB=imread(newName);
        image(RGB);
    end
    delete(tmpName);
end
fprintf('\nCorrect key value find is %d',correctKey(ind));
fprintf('\nNumber of worker used: %d',nWorker);
fprintf('\nTime spent for decrypt RSA: %.3f s',timeElapsed);
fprintf('\n********************FINISH********************************\n\n\n')
delete(poolobj);

