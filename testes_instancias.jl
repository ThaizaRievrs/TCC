include("IRP.jl")
include("abs1n5.dat")
#include("abs1n10.dat")

# DECLARAR VETORES

lines = readlines("abs1n5.dat")
n = split(lines[1])[1] # fornecdedor + clientes
num_veiculos = 2 # 2 e 3
num_periodos = split(lines[1])[2]
Cap_veiculos1 = split(lines[1])[3]
for v = 2:num_veiculos
    Cap_veiculos[v] = Cap_veiculos1
end
# Fornecedor linha 2
x[1] = split(lines[2])[2]
y[1] = split(lines[2])[3]
I0[1] = split(lines[2])[4]
H[1] = split(lines[2])[6]
for f = 1:num_periodos
    r[f] = split(lines[2])[5]
end
# Clientes
for c = 3:n+1
    x[c-1] = split(lines[c])[2]
    y[c-1] = split(lines[c])[3]
    I0[c-1] = split(lines[c])[4]
    Cap_estoque[c-2] = split(lines[c])[5]
    for t = 1:num_periodos
        Demanda[c-2][t] = split(lines[c])[7]
    end
    H[c-1] = split(lines[c])[8]
 end
 for i = 1:n
     custo[i][i] = 1
     for j = i+1:n
         custo[i][j] = ((x[i]-x[j])^2 + (y[i]-y[j])^2)^(1/2)
         custo[j][i] = custo[i][j] #não sei se é necessario
     end
 end
 solveIRP(H,I0,r, Cap_estoque,Demanda,custo,num_veiculos,Cap_veiculos,num_periodos)
