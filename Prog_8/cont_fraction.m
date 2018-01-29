function y = cont_fraction(e,n)
%Computes the continuous fraction of e/n

e = java.math.BigDecimal(e);
n = java.math.BigDecimal(n);
flag = true;
y = [];
while(flag)
    %Makes the division
    temp = e.divideToIntegralValue(n);
    %Might want to preallocate memory for performance issues
    % y = [y; temp.toPlainString()];
    y(end+1) = temp;
    temp = e.subtract(temp.multiply(n));
    %if the next == 0 break loop
    if temp.compareTo(java.math.BigDecimal('0')) == 0
        flag = false;
    end;
    e = n;
    n = temp;

end;

return;

end