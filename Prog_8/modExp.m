function y = modExp( b, e, n ) % y = b^e(mod n)
    if (n==1)
        y = 0;
        return
    end
    y = uint64(1);
    b = mod(b,n);
    while (e > 0)
        if (mod(e,2)==1)
            y = mod((y*b),n);
        end
        e = bitshift(e,-1);
        b = mod((b*b),n) ;
    end
end