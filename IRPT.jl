using JuMP
using Gurobi

function solveIRPT(H,            # Custo de manutencao de estoque
                  I0,           # nível de estoque inicial
                  r,            # quantidade de produto disponibilizada pelo fornecedor
                  Cap_estoque,  # Capacidade de estoque só de clientes
                  Demanda,      # Demanda[i,t] matriz por periodo
                  custo,        # matriz de custo de viagem simétrica
                  num_veiculos, # numero de veiculos
                  Cap_veiculos, # capacidade de cada veiculo
                  num_periodos, # numero de periodos
                  b,            # custo do transbordo
                  R) #todos os clientes

  num_clientes = length(H) - 1

  IRPT = Model(solver = GurobiSolver())#(TimeLimit = 15))

  # q quantidade de produto entregue pelo fornecedor para o cliente i no periodo t
  @variable(IRPT, q[i = 1:num_clientes, t = 1:num_periodos] >= 0, Int)
  # nivel de estoque no periodo (clientes e fornecedor)
  @variable(IRPT, I[i = 0:num_clientes, t = 0:num_periodos] >= 0, Int)
  # numero de vezes que o caminho (i,j) é usado no periodo t
  @variable(IRPT, x[i = 0:num_clientes, j = 0:num_clientes, t = 1:num_periodos], Bin)
  # w quantidade de produto entregue de um cliente i para um cliente j (terceirizado)
  @variable(IRPT, w[j = 0:num_clientes, i = 1:num_clientes, t = 1:num_periodos] >= 0, Int)# criar restrição para zerar os outros
  # variavel v
  @variable(IRPT, 0 <= v[i = 1:num_clientes, t = 1:num_periodos] <= Cap_veiculos, Int)

  @objective(IRPT, Min, sum(custo[i + 1, j + 1] * x[i, j, t] for i = 0:num_clientes,
                                                              j = 0:num_clientes,
                                                              t = 1:num_periodos)
                       + sum(H[1] * I[0, t] for t = 1:num_periodos)
                       + sum(H[i + 1] * I[i, t] for i = 1:num_clientes,
                                                   t = 1:num_periodos)
                       + sum(b[i+1, j+1]*w[i, j, t] for i = [0;R],
                                                 j = 1:num_clientes,
                                                 t = 1:num_periodos))

  # I[i,t] relaciona o nivel com o periodo inicial
  for i = 0:num_clientes
    @constraint(IRPT, I[i, 0] == I0[i+1])
  end

  # restrição 2:
  @constraint(IRPT, [t = 1:num_periodos], I[0, t] == I[0, t-1] + r[t] - sum(q[i, t] for i = 1:num_clientes) - sum(w[0, i, t] for i = 1:num_clientes))
  # restrição 4:
  @constraint(IRPT, [i = 1:num_clientes, t = 1:num_periodos], I[i, t] == I[i, t-1] + w[0, i, t] + sum(w[j, i, t] for j = R)- sum(w[i, j, t] for j = 1:num_clientes) - Demanda[i, t] + q[i, t])
  # restrição 6:
  @constraint(IRPT, [i = 1:num_clientes, t = 1:num_periodos], I[i, t] <= Cap_estoque[i])
  # restrição 8:
  @constraint(IRPT, [i = 1:num_clientes, t = 1:num_periodos], q[i, t] <= Cap_estoque[i] - I[i, t-1])
  # restrição 7:
  @constraint(IRPT, [i = 1:num_clientes, t = 1:num_periodos], q[i, t] >= Cap_estoque[i]*sum(x[i, j, t] for j = 0:num_clientes) - I[i, t-1])
  # restrição 9:
  @constraint(IRPT, [i = 1:num_clientes, t = 1:num_periodos], q[i, t] <= Cap_estoque[i]*sum(x[i, j, t] for j = 0:num_clientes))
  # restrição 10:
  @constraint(IRPT, [t = 1:num_periodos], sum(q[i, t] for i = 1:num_clientes) <= Cap_veiculos)
  # restrição 11:
  @constraint(IRPT, [j = 0:num_clientes, t = 1:num_periodos], sum(x[i, j, t] for i = 0:num_clientes) == sum(x[j, i, t] for i = 0:num_clientes))
  # restrição 12:
  @constraint(IRPT, [t = 1:num_periodos], sum(x[i, 0, t] for i = 0:num_clientes) <= 1)
  # restrição 13:
  @constraint(IRPT, [i = 1:num_clientes, j = 1:num_clientes, t = 1:num_periodos], v[i, t] - v[j, t] + Cap_veiculos*x[i, j, t] <= Cap_veiculos - q[j, t])
  # restrição 14:
  @constraint(IRPT, [i = 1:num_clientes, t = 1: num_periodos], q[i, t] <= v[i, t])

  solucao = solve(IRPT)
  b = getobjectivebound(IRPT)
  f = getobjectivevalue(IRPT)
  time = getsolvetime(IRPT)
  return b, f, time

end #end função
