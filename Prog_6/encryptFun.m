function out = encryptFun( A, key, type )

    if strcmp(type,'xor')
        out=bitxor(A,key,'uint8');
    else
        out=bitxor(A,key,'uint8');
    end

end

