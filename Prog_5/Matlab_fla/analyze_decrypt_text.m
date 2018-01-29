function find = analyze_decrypt_text( decrypt_BF_text, dictionary, perc )

    find=0;
    words=string(0);
    remain=decrypt_BF_text;
    while (~isempty(remain))
        [token,remain] = strtok(remain, ' ,.:)(');
        words = [words ; token];
    end
    fprintf('\nNumero parole trovate: %d', length(words));
    
    
%     words
%     if length(words) < (length(decrypt_BF_text)/6)
%         fprintf('\nTroppe poche parole');
%         return 
%     end
    
    cont=0;
    for k=1:length(words)
        ind= words(k)== dictionary;     
        if(sum(ind)>0)
            cont=cont+1;
        end   
    end
    fprintf('\nNumero parola presenti nel dizionario: %d', cont);
    fprintf('\nPercentuale parole combacianti sul totale: %.2f',(cont/length(words)))
    if ((cont/length(words))>perc)
        find=1;
    else
        find=0;
    end
    
    return
    
end

