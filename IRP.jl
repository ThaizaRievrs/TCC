using JuMP
using Gurobi
using Graphs


function PrintSolucao(solucao, num_clientes, num_veiculos, num_periodos, x, q, y, I, r)
  println("RESULTADO:")
  if solucao == :Optimal
    for i = 0:num_clientes, j = i+1:num_clientes, k = 1:num_veiculos, t = 1:num_periodos
      if x[i,j,k,t] != 0
        println(" x[$i,$j,$k,$t] = $(x[i,j,k,t])")
      end
    end
    for i = 1:num_clientes, k = 1:num_veiculos, t = 1:num_periodos
      if q[i,k,t] != 0
        println(" q[$i,$k,$t] = $(q[i,k,t])")
      end
    end
    for i = 0:num_clientes, k = 1:num_veiculos, t = 1:num_periodos
      if y[i,k,t] != 0
        println(" y[$i,$k,$t] = $(y[i,k,t])")
      end
    end
    for i = 0:num_clientes, t = 0:num_periodos
      println(" I[$i,$t] = $(I[i,t])")
    end
    for t = 1:num_periodos
      println(" r[$t] = $(r[t])")
    end
  else
    println(" Sem soluçao")
  end
  println(" ")
end #end função

function solveIRP(H,            # Custo de manutencao de estoque
                  I0,           # nível de estoque inicial
                  r,            # quantidade de produto disponibilizada pelo fornecedor
                  Cap_estoque,  # Capacidade de estoque só de clientes
                  Demanda,      # Demanda[i,t] matriz por periodo
                  custo,        # matriz de custo de viagem simétrica
                  num_veiculos, # numero de veiculos
                  Cap_veiculos, # capacidade de cada veiculo
                  num_periodos)  # numero de periodos


  num_clientes = length(H) - 1

  IRP = Model(solver=GurobiSolver())

  # q quantidade de produto entregue pelo fornecedor para o cliente i com o veiculo k no periodo t
  @variable(IRP, q[i = 1:num_clientes, k = 1:num_veiculos, t = 1:num_periodos] >= 0, Int)
  # nivel de estoque no periodo (clientes e fornecedor)
  @variable(IRP, I[i = 0:num_clientes, t = 0:num_periodos] >= 0, Int)
  # numero de vezes que o caminho (i,j) é usado pelo veiculo k no periodo
  @variable(IRP, x[i = 0:num_clientes, j = i+1:num_clientes, k = 1:num_veiculos, t = 1:num_periodos] >= 0, Int)
  # se cliente i é visitado pelo veiculo k no periodo = 1
  @variable(IRP, y[i = 0:num_clientes, k = 1:num_veiculos, t = 1:num_periodos], Bin)

  @objective(IRP, Min, sum(custo[i + 1,j + 1] * x[i,j,k,t] for i = 0:num_clientes,
                                                                j = i+1:num_clientes,
                                                                  k = 1:num_veiculos,
                                                                    t = 1:num_periodos)
                       + sum(H[i + 1] * I[i,t] for i = 0:num_clientes,
                                                    t = 0:num_periodos))

  # I[i,t] relaciona o nivel com o periodo inicial
  for i = 0:num_clientes
    @constraint(IRP, I[i,0] == I0[i+1])
  end
  for i = 0:num_clientes, j = i+1:num_clientes, k = 1:num_veiculos, t = 1:num_periodos
    if i == 0
      setupperbound(x[i,j,k,t], 2)
    else
      setupperbound(x[i,j,k,t], 1)
    end
  end

  # restrição 2:
  @constraint(IRP, [t = 1:num_periodos], I[0,t] == I[0,t-1] + r[t] - sum(q[i,k,t] for k = 1:num_veiculos,
                                                                                        i = 1:num_clientes))
  # restrição 4:
  @constraint(IRP, [i = 1:num_clientes, t = 1:num_periodos], I[i,t] == I[i,t-1] - Demanda[i,t] + sum(q[i,k,t] for k = 1:num_veiculos))
  # restrição 6:
  @constraint(IRP, [i = 1:num_clientes, t = 1:num_periodos], I[i,t] <= Cap_estoque[i])
  # restrição 7:
  @constraint(IRP, [i = 1:num_clientes, t = 1:num_periodos], sum(q[i,k,t] for k = 1:num_veiculos) <= Cap_estoque[i] - I[i,t-1])
  # restrição 8:
  @constraint(IRP, [i = 1:num_clientes, k = 1:num_veiculos, t = 1:num_periodos], q[i,k,t] >= Cap_estoque[i]*y[i,k,t] - I[i,t-1])
  # restrição 9:
  @constraint(IRP, [i = 1:num_clientes, k = 1:num_veiculos, t = 1:num_periodos], q[i,k,t] <= Cap_estoque[i]*y[i,k,t])
  # restrição 10:
  @constraint(IRP, [k = 1:num_veiculos,  t = 1:num_periodos], sum(q[i,k,t] for i = 1:num_clientes) <= Cap_veiculos[k]*y[0,k,t])
  # restrição 11:
  @constraint(IRP, [i = 0:num_clientes, k = 1:num_veiculos, t = 1:num_periodos], sum(x[i,j,k,t] for j = i+1:num_clientes) + sum(x[j,i,k,t] for j = 0:i-1) == 2*y[i,k,t])

  function lazyConstraintsCallback(cb)
    Tours = Vector{Vector{Int}}()
    # Criando um grafo
    for t = 1:num_periodos, k = 1:num_veiculos
      g = simple_graph(num_clientes+1, is_directed=false)
      for i in 0:num_clientes, j in i+1:num_clientes
        if i != j
          if getvalue(x[i, j, k, t]) > 0.01
            add_edge!(g, i+1, j+1) # Arestas
          end
        end
      end
      # Encontrando os componentes conexos do grafo
      cc = connected_components(g)
      if length(cc) > 1
        for c in cc
          if length(c) > 1
            ord = sort(c)
            if ord[1] != 1
              push!(Tours, c)
            end
          end
        end
      end
    end

    for Tour in Tours
      subtourLhs = AffExpr()
      subtourRhs = AffExpr()
      # Encontrando arestas do subciclo
      for t = 1:num_periodos
        for k = 1:num_veiculos
          subtourRhs = 0
          subtourLhs = 0
          for i in Tour
            for j in Tour
              if i < j && getvalue(x[i-1, j-1, k, t]) > 0.01
                subtourLhs += x[i-1, j-1, k, t]
              end
            end
            getvalue(y[i-1, k, t])
            subtourRhs += y[i-1, k, t]
          end
          for m in Tour
            # restrição 12:
            @lazyconstraint(cb, subtourLhs <= subtourRhs - y[m-1, k, t])
          end
        end
      end
    end
  end # Function

  addlazycallback(IRP, lazyConstraintsCallback)
  solucao = solve(IRP)

  if solucao == :Optimal
    x = getvalue(x) # Pega o valor de x
    q = getvalue(q) # Pega o valor de q
    y = getvalue(y) # Pega o valor de y
    I = getvalue(I) # Pega o valor de I
    PrintSolucao(solucao, num_clientes, num_veiculos, num_periodos, x, q, y, I, r)
  else
    print("Sem solução")
  end

end #end função
