function [d, q, a, b, f] = extendedEuclidean_forward(p, q)
   %  return array [d, a, b] such that d = gcd(p, q), ap + bq = d
  f = [];

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
end