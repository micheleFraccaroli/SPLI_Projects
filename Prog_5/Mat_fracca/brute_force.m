%% Start
close all;
clear all;
clc;

shift=3;
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

fileIDWriteCrypt=fopen('criptato/crypted_text.txt','w');
fprintf(fileIDWriteCrypt,'%s',crypted_text);
fclose(fileIDWriteCrypt);
fprintf('\nTesto criptato...')
%% Brute force
fprintf('\n----------------Brute Force Decryption---------------')
text_crypted=fileread('criptato/crypted_text.txt');
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
        fileIDWriteDecryptBF=fopen('decriptato/decrypt_BF_text.txt','w');
        fprintf(fileIDWriteDecryptBF,'%s',decrypt_BF_text);
        fclose(fileIDWriteDecryptBF);
        fprintf('\nDecriptato BF\n')
        break;
    end    
end
if is_find==0
    fileIDWriteDecryptBF=fopen('decriptato/decrypt_BF_text.txt','w');
    fprintf(fileIDWriteDecryptBF,'%s','Fail to decrypt with the brute force approach.');
    fclose(fileIDWriteDecryptBF);
    fprintf('\n###############Decryption failed BF##################\n')
end
toc;