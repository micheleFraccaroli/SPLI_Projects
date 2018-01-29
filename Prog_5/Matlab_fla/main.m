Start
close all;
clear all;
clc;

shift=5;
full_coding=1;
perc_dec=0.7;
file_name='Logos.txt';
path=strcat('',file_name);

fprintf('\nStart....');
alphabet=[char('A'+(1:26)-1) char('a'+(1:26)-1)];
asciiFileID=fopen('ascii_table.txt','r');
dictionaryFileID=fopen('italian.txt','r');
asciiTable=textscan(asciiFileID,'%d\t%s');
dictionary=textscan(dictionaryFileID,'%s');
dictionary=string(dictionary{1,1});
fclose(asciiFileID);
fclose(dictionaryFileID);
% Completa ascii table or alphabet(capital and not)
if full_coding==1
    letters=char(asciiTable{1,2});
else
    letters=alphabet;
end

text_test=fileread(path);
fprintf('\nEnd first part...');
%% Encryption
fprintf('\nEncrypting file %s...',file_name); 
if full_coding==1
    cryptLetters=circshift(letters,shift,1);
else
    cryptLetters=circshift(letters,shift);
end

crypted_text='';
for i=1:length(text_test)
    ind=text_test(i)==letters;
    if full_coding==1
        let=cryptLetters(ind(:,1,1));
    else
        let=cryptLetters(ind);
    end
    if isempty(let)
        crypted_text(i)=text_test(i);
    else
        crypted_text(i:i+length(let)-1)=let';
    end
%     crypt_length=length(crypted_text);
end

fileIDWriteCrypt=fopen('crypted_text.txt','w');
fprintf(fileIDWriteCrypt,'%s',crypted_text);
fclose(fileIDWriteCrypt);
fprintf('\nTesto criptato...')

%% Decryption
text_crypted=fileread('crypted_text.txt');
decrypt_text='';
for i=1:length(text_crypted)
    ind=text_crypted(i)==cryptLetters;
    let=letters(ind);
    if isempty(let)
        decrypt_text(i)=text_crypted(i);
    elsescusate ora non sto al pc pero dal cellulare ho notato l errore di sintassi,ho modificato il mio messaggio iniziate inserendo la maledetta virgola nel print.

        decrypt_text(i:i+length(let)-1)=let';
    end
%     decrypt_length=length(decrypt_text);
end
fileIDWriteDecrypt=fopen('texts/decrypt_text.txt','w');
fprintf(fileIDWriteDecrypt,'%s',decrypt_text);
fclose(fileIDWriteDecrypt);
fprintf('\nTest decriptato con ')
%% Brute force
fprintf('\n----------------Brute Force Decryption---------------')
text_crypted=fileread('crypted_text.txt');
tic;
for k=1:length(letters)
    decrypt_BF_text='';
    if full_coding==1
        cryptLetters=circshift(letters,k,1);
    else
        cryptLetters=circshift(letters,k);
    end
    
    for i=1:length(text_crypted)
        ind=text_crypted(i)==cryptLetters;
        let=letters(ind);
        if isempty(let)
            decrypt_BF_text(i)=text_crypted(i);
        else
            decrypt_BF_text(i:i+length(let)-1)=let';
        end
    end
    fprintf('\n**************Shift provato: %d**********************', k);
    is_find=analyze_decrypt_text(decrypt_BF_text,dictionary,perc_dec);
    
    if is_find==1
        fileIDWriteDecryptBF=fopen('decrypt_BF_text.txt','w');
        fprintf(fileIDWriteDecryptBF,'%s',decrypt_BF_text);
        fclose(fileIDWriteDecryptBF);
        fprintf('\nDecriptato BF\n')
        break;
    end    
end
if is_find==0
    fileIDWriteDecryptBF=fopen('decrypt_BF_text.txt','w');
    fprintf(fileIDWriteDecryptBF,'%s','Fail to decrypt with the brute force approach.');
    fclose(fileIDWriteDecryptBF);
    fprintf('\n###############Decryption failed BF##################\n')
end
toc;
%% Frequency
fprintf('\n------------------Frequency Decryption-----------------')
tic;
if full_coding==1
    letters=letters(:,1,1);
end

text_crypted=fileread('crypted_text.txt');
lettersForCompare=letters;

freq=zeros(1,length(lettersForCompare));

for j=1:length(lettersForCompare)
    if any(lettersForCompare(j)==text_crypted)
        ind=text_crypted==lettersForCompare(j);
        freq(j)=sum(ind);
    else
        freq(j)=0;
    end
end
freq=freq/sum(freq);



% figure;
% stem(freq)
% xticks((1:length(lettersForCompare)))
% xticklabels(mat2cell(lettersForCompare,size(lettersForCompare,1),ones(1,size(lettersForCompare,2))))


freqFileID=fopen('frequency.txt','rt');
freq_file=textscan(freqFileID,'%d %s %d','whitespace',' ');
freqLetters=string(freq_file{1,2});
% -1 � lo spazio
ind=freqLetters=='-1';
freqLetters(ind)=' ';
freqLetters=freqLetters(:,1);
freqExt=double(freq_file{1,3});
fclose(freqFileID);

freqExt=freqExt/sum(freqExt);
[freqLetters, ind]=sort(freqLetters);
freqExt=freqExt(ind);

% figure;
% stem(freqExt)
% xticks((1:length(freqLetters)))
% xticklabels(mat2cell(freqLetters,size(freqLetters,1),ones(1,size(freqLetters,2))))

freqForCompare=zeros(1,length(letters));
tempLetters=letters;
for j=1:length(letters)
    if any(tempLetters(j)==freqLetters)
        ind=tempLetters(j)==freqLetters;
        freqForCompare(j)=freqExt(ind);
    else
        freqForCompare(j)=0;
    end
end

% figure;
% stem(freqForCompare)
% xticks((1:length(tempLetters)))
% xticklabels(mat2cell(tempLetters,size(tempLetters,1),ones(1,size(tempLetters,2))))

[acor, lag]=xcorr(freqForCompare,freq);
[~,I] = max(abs(acor));
if lag(I)<0
    max_shift = length(letters)+lag(I);
else
    max_shift = lag(I);
end

fprintf('\nShift utilizzato: %d\tShift stimato: %d',shift,max_shift);

half=floor(length(letters)/2);
shiftPlot=(0:length(letters));
pos=acor(lag>=0);
neg=acor(lag<0);
signifAcor=[pos(1:end/2+1) neg(1:end/2+1)];
figure;
stem(shiftPlot,signifAcor)
xlabel('# shift');
ylabel('Magnitude corr.');
axis([0 length(letters) 0 inf])
hold on;
[ymax, index]=max(signifAcor);
stem(index-1,ymax,'xr')
legend('xcorr','max');


decrypt_Freq_text='';
cryptLetters=circshift(letters,max_shift);
for i=1:length(text_crypted)
    ind=text_crypted(i)==cryptLetters;
    let=letters(ind);
    if isempty(let)
        decrypt_Freq_text(i)=text_crypted(i);
    else
        decrypt_Freq_text(i:i+length(let)-1)=let';
    end
end
fileIDWriteDecryptFreq=fopen('decrypt_Freq_text.txt','w');
fprintf(fileIDWriteDecryptFreq,'%s',decrypt_Freq_text);
fclose(fileIDWriteDecryptFreq);
fprintf('\nDecriptato Freq\n')
toc;
