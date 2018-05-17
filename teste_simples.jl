include("IRP.jl")

H=[1,1,1,1,1]
I0=[50000,5000,3000,2000,4000]
Cap_estoque=[5000,3000,2000,4000]
Demanda=[1000 0;
         3000 3000;
         2000 2000;
         1500 0]
custo=[1 100 100 100 100;
       100 1 10 150 160;
       100 10 1 140 150;
       100 150 140 1 10;
       100 160 150 10 1]
num_veiculos= 2
Cap_veiculos=[5000,5000]
num_periodos=1
solveIRP(H,I0,Cap_estoque,Demanda,custo,num_veiculos,Cap_veiculos,num_periodos)
