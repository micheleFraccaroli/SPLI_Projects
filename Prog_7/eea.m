function [x, y] = eea(p, q)
f = [];
x = 0;
y = 1;
while (q(end) ~= 0)
    f = [f floor(p(end)/q(end))];
    p = [p q(end)];
    q = [q mod(p(end-1), q(end))];
end

% updates
q = q(1:(end));
d = p(1:(end-1));
a = 1;
b = 0;

numberOfSteps = numel(f) - 1;
step = 1;

for i = (numberOfSteps):-1:1
    
    if (mod(step, 2) ~= 0)
        x = x + y * f(i);
    else
        y = y + x * f(i);
    end
    
    step = step + 1;
end

x = x * (-1);

if (gcd(d(1),q(1)) == (x * d(1) + y * q(1)))
    x = y;
    y = x;
end
end