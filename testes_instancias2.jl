include("IRPT.jl")

function roda_instancia2(instancia, num_veiculos=1)

    lines = readlines(instancia)

    # dados
    n = parse(split(lines[1])[1]) # fornecdedor + clientes
    num_veiculos = 1   #2 e 3
    num_periodos = parse(split(lines[1])[2])
    Cap_veiculos = zeros(num_veiculos)
    Cap_veiculos = parse(split(lines[1])[3])

    # definindo vetores e matrizes
    x = zeros(n)
    y = zeros(n)
    I0 = zeros(n)
    H = zeros(n)
    r = zeros(num_periodos)
    Cap_estoque = zeros(n-1)
    Demanda = zeros(n-1,num_periodos)
    custo = zeros(n,n)
    b = zeros(n,n)
    # R = zeros(n-1)

    # Fornecedor
    x[1] = parse(split(lines[2])[2])
    y[1] = parse(split(lines[2])[3])
    I0[1] = parse(split(lines[2])[4])
    H[1] = parse(split(lines[2])[6])
    for l = 1:num_periodos
        r[l] = parse(split(lines[2])[5])
    end

    # Clientes
    for c = 3:n+1
        x[c-1] = parse(split(lines[c])[2])
        y[c-1] = parse(split(lines[c])[3])
        I0[c-1] = parse(split(lines[c])[4])
        Cap_estoque[c-2] = parse(split(lines[c])[5])
        for t = 1:num_periodos
            Demanda[c-2,t] = parse(split(lines[c])[7])
        end
        H[c-1] = parse(split(lines[c])[8])
    end
    for i = 1:n
        for j = 1:n
            custo[i,j] = round(Int, sqrt((x[i]-x[j])^2 + (y[i]-y[j])^2))
            b[i,j] = 1*custo[i,j]
        end
    end
    R = 1:n-1
    return solveIRPT(H, I0, r, Cap_estoque, Demanda, custo, num_veiculos, Cap_veiculos, num_periodos, b, R)
end #end função

roda_instancia2("high3/abs1n5.dat")
# For que roda todos os arquivos de teste:

#=for dir in ["high3"]#["low3", "low6", "high3", "high6"]
    files = readdir(dir)
    open("$dir-ResultadosIRPTbc.csv", "w") do output
        for (i,file) in enumerate(files)
            b, f, time = roda_instancia2("$dir/$file")
            gap = abs(b-f)/abs(f)
            println(output, "$file,$f,$b,$gap,$time")
        end
    end
end=#
