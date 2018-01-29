%% extendede euclidian algorithm

tic;

key = 7;
modulo = 2^32;

[x, y] = eea(modulo, key);
if (x < 0)
    decr = modulo + x;
else
    decr = x;
end
fprintf("\ndecr(+)-----> %d\n", decr);
toc;

%% START euclidian-algorithm
tic;
key = 5;
modulo = 2^32;
[d, q, a, b, f] = extendedEuclidean_forward(modulo,key);
[x, y] = extendedEuclidean_backSubstitution (d, q, a, b, f);
if (x < 0)
    decr = modulo + x;
else
    decr = x;
end
fprintf("\nThis is my decription-key: %d\n", decr);
toc;