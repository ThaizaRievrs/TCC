using JuMP, Gurobi

function PrintSolucao(solucao, num_clientes, num_veiculos, num_periodos, x) 
    println("RESULTADO:")
    if solucao == :Optimal
      for i = 1:num_clientes
        for j = 1:num_clientes #in?
          for k = 1:num_veiculos
            for t = 1:num_periodos
          println("  $(q[i,k,t]) : $(getvalue(x[i,j,k,t]))")
            end
          end
        end
      end
    else
        println(" Sem soluçao")
    end
    println("")
end

# i, j  {1:num_clientes}
# t {1:num_periodos}
function solveIRP(H,            # Custo de manutencao de estoque
                  I0,           # nível de estoque inicial
                  Cap_estoque,  # Capacidade de estoque só de clientes
                  Demanda,      # Demanda[i,t] matriz por periodo
                  custo,        # matriz de custo de viagem simétrica
                  num_veiculos, # numero de veiculos
                  Cap_veiculos, # capacidade de cada veiculo
                  num_periodos  # numero de periodos 
                 )

  num_clientes = length(H) - 1
  
  IRP = Model(solver=GurobiSolver())
  
  # q quantidade de produto entregue pelo fornecedor para o cliente i com o veiculo k no periodo t
  @variable(IRP, q[i=1:num_clientes,k=1:num_veiculos,t=1:num_periodos] >= 0, Int)
  # r quantidade de produtos disponibilizada pelo fornecedor no periodo t
  @variable(IRP, r[t=1:num_periodos], Int)
  # nivel de estoque no periodo (clientes)
  @variable(IRP, I[i=1:num_clientes,t=1:num_periodos] >= 0, Int)
  # nivel de estoque no periodo (fornecedor)
  @variable(IRP, I[0,t=1:num_periodos] >= 0, Int) 
  # variavel só é usada na restrição 11 segundo somatório
  @variable(IRP, 0 <= x0[i=1:num_clientes,k=1:num_veiculos,t=1:num_periodos] <= 2, Int) # {0,1,2}
  # numero de vezes que o caminho (i,j) é usado pelo veiculo k no periodo  
  @variable(IRP, x[i=1:num_clientes,j=1:num_clientes,k=1:num_veiculos,t=1:num_periodos], Bin)
  # se cliente i é visitado pelo veiculo k no periodo = 1
  @variable(IRP, y[i=0:num_clientes,k=1:num_veiculos,t=1:num_periodos], Bin)

  @objective(IRP, sum(custo[i + 1,j + 1] * x[i,j,k,t] for i=0:num_clientes,
                                                      j=i+1:num_clientes,
                                                      k=1:num_veiculos,
                                                      t=1:num_periodos)
                + sum(H[i + 1] * I[i,t] for i=0:num_clientes,
                                        t=0:num_periodos))
 
  # I[i,t] relaciona o nivel com o periodo inicial
  for i = 0:num_clientes
    @constraint(IRP, I[i,0] == I0[i+1])
  end

  for t = 1:num_periodos 
    # restrição 2:    
    @constraint(IRP, I[0,t] = I[0,t-1] + r[t] - sum(q[i,k,t] for k=1:num_veiculos, 
                                                             i=1:num_clientes))
    # restrição 4:                                                         
    @constraint(IRP, Cliente[i=1:num_clientes], I[i,t] = I[i,t-1] - Demanda[i,t] 
                                                       + sum(q[i,k,t] for k=1:num_veiculos)) 
    # restrição 6:                                                   
    @constraint(IRP, Cliente[i=1:num_clientes], I[i,t] <= Cap_estoque[i]) 
    # restrição 7:   
    @constraint(IRP, Cliente[i=1:num_clientes], sum(q[i,k,t] for k=1:num_veiculos) <= Cap_estoque[i] - I[i,t-1])
    # restrição 8:  
    @constraint(IRP, Cliente[i=1:num_clientes], 
                     veiculo[k=1:num_veiculos], q[i,k,t] => Cap_estoque[i]*y[i,k,t] - I[i,t-1]) 
    # restrição 9:                 
    @constraint(IRP, Cliente[i=1:num_clientes], 
                     veiculo[k=1:num_veiculos], q[i,k,t] <= Cap_estoque[i]*y[i,k,t]) 
    # restrição 10:                 
    @constraint(IRP, veiculo[k=1:num_veiculos], sum(q[i,k,t] for i=1:num_clientes) <= Cap_veiculos[k]*y[0,k,t])
    # restrição 11:
    @constraint(IRP, Cliente[i=1:num_clientes], 
                     veiculo[k=1:num_veiculos], sum(x[i,j,k,t] for j=i+1:num_clientes) 
                                              + sum(x[i,j,k,t] for j=0:i-1) = 2*y[i,k,t])   
  end

  solucao = solve(IRP)
  #println("solucao = $solucao")
  #x = getvalue(x) # Pega o valor de x
  if solution == :Optimal
    result = x
    PrintSolucao(solucao, num_clientes, num_veiculos, num_periodos, x)
  else
    result = solucao
    print("Sem solução")
  end
  result
end
