include("IRP.jl")
H=[1,1,1,1,1,1,1]
I0=[500000,0,0,0,0,0,0]
r=[0, 0]
Cap_estoque=[5000,3000,2000,4000,5000,4000]
Demanda=[1000 1000;
         3000 3000;
         2000 2000;
         1500 1500;
         1000 1000;
         1500 1500]
custo=[  1 100 100 100 100 100 100;
       100   1  10 150 160 200 200;
       100  10   1 140 150 200 200;
       100 150 140   1  10   1   1;
       100 160 150  10   1 200 200;
       100 200 200   1  200  1   1;
       100 200 200   1  200  1   1]
num_veiculos= 2
Cap_veiculos=[50000,50000]
num_periodos=2
solveIRP(H,I0,r, Cap_estoque,Demanda,custo,num_veiculos,Cap_veiculos,num_periodos)
