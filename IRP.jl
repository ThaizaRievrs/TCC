using JuMP, Gurobi

#function PrintSolution(status, plants, markets, ship)
#    println("RESULTS:")
#    if status == :Optimal
#      for i = 1:length(plants)
#        for j in 1:length(markets)
#          println("  $(plants[i]) $(markets[j]) = $(getvalue(ship[i,j]))")
#        end
#      end
#    else
#        println("  No solution")
#    end
#    println("")
#end

# i, j  {1:num_clientes}
# t ...
function solveIRP(H,            # Custo de manutencao de estoque
                  I0,           # ...
                  Cap_estoque,
                  Demanda,      # Demanda[i,t]
                  custo,
                  num_veiculos,
                  Cap_veiculos,
                  num_periodos
                 )

  num_clientes = length(H) - 1
  
  IRP = Model(solver=GurobiSolver())
  
  # q quantidade de produtos disponibilizada pelo fornecedor no periodo t
  @variable(IRP, q[i=1:num_clientes,k=1:num_veiculos,t=1:num_periodos] => 0)   
  @variable(IRP, r[t=1:num_periodos])
  @variable(IRP, I[i=1:num_clientes,t=1:num_periodos] => 0)
  @variable(IRP, I[0,t=1:num_periodos] => 0) 
  @variable(IRP, 0 <= x0[i=1:num_clientes,k=1:num_veiculos,t=1:num_periodos] <= 2, Int) # {0,1,2}
  @variable(IRP, x[i=1:num_clientes,j=1:num_clientes,k=1:num_veiculos,t=1:num_periodos], Bin)
  @variable(IRP, y[i=0:num_clientes,k=1:num_veiculos,t=1:num_periodos], Bin)

  @objective(IRP, sum(custo[i + 1,j + 1] * x[i,j,k,t] for i=0:num_clientes,
                                                      j=i+1:num_clientes,
                                                      k=1:num_veiculos,
                                                      t=1:num_periodos)
                + sum(H[i + 1] * I[i,t] for i=0:num_clientes,
                                        t=0:num_periodos))
 
  # I[i,t] relaciona o nivel com o periodo
  for i = 0:num_clientes
    @constraint(IRP, I[i,0] == I0[i+1])
  end

  for t = 1:num_periodos 
    @constraint(IRP, I[0,t] = I[0,t-1] + r[t] - sum(q[i,k,t] for k=1:num_veiculos, 
                                                             i=1:num_clientes))
                                                           
    @constraint(IRP, Cliente[i=1:num_clientes], I[i,t] = I[i,t-1] - Demanda[i,t] 
                                                       + sum(q[i,k,t] for k=1:num_veiculos)) 
                                                     
    @constraint(IRP, Cliente[i=1:num_clientes], I[i,t] <= Cap_estoque[i]) 
  
    @constraint(IRP, Cliente[i=1:num_clientes], sum(q[i,k,t] for k=1:num_veiculos) <= Cap_estoque[i] - I[i,t-1])
  
    @constraint(IRP, Cliente[i=1:num_clientes], 
                     veiculo[k=1:num_veiculos], q[i,k,t] => Cap_estoque[i]*y[i,k,t] - I[i,t-1]) 
                   
    @constraint(IRP, Cliente[i=1:num_clientes], 
                     veiculo[k=1:num_veiculos], q[i,k,t] <= Cap_estoque[i]*y[i,k,t]) 
                   
    @constraint(IRP, veiculo[k=1:num_veiculos], sum(q[i,k,t] for i=1:num_clientes) <= Cap_veiculos[k]*y[0,k,t])
  
    @constraint(IRP, Cliente[i=1:num_clientes], 
                     veiculo[k=1:num_veiculos], sum(x[i,j,k,t] for j=i+1:num_clientes) 
                                              + sum(x[i,j,k,t] for j=0:i-1) = 2*y[i,k,t])   
  end

  status = solve(IRP)
  println("status = $status")
  x = getvalue(x) # Pega o valor de x
end
