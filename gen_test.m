%octave matlab
clearvars
N = 1:200;
a = 11*((2*pi)/length(N));
temp = 0;
sig = 1:200;
arg = 0;

for i = (1:length(N))
  arg = arg + a;
  temp = arg;
  m = 0;
  while(temp > 0.03125)
    temp = temp/2;
    m++;
  end
  if(m == 0)
    sig(i) = temp;
    continue;
  endif
  cosa = 1-((temp^2)/2);
  sina = temp;
  for cnt = 1:m
    sin2a = 2*sina*cosa;
    cos2a = 1-2*(sina^2);
    sina  = sin2a;
    cosa  = cos2a;
  end
  sig(i) = sina;
end
plot(N, sig);
