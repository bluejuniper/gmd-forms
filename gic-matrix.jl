using JSON, PowerModelsGMD

path = "data/tx2000.json"
path = "data/b4gic.m"
path = "data/epri21.m"

#path = "data/eastern-fixed.json"
#path = "data/northeast-fixed.json"
#path = "data/northeast.json"
#path = "data/isone.json"

println("Start loading $path")
net = PowerModels.parse_file(path)
#h = open(path)
#net = JSON.parse(h)
#close(h)
println("Done loading $path")

println("Start solving $path")
##function run_gic_matrix(net)
# We will be solving for bus to ground currents.  We have two matrices to 
# worry about, Y and Z.  Both are nxn where n is the number of busses.  Y
# is symetric and, for now, Z is diagonal.

######
# I assume the branchListStruct and busListStruct are snatched directly from
# jsondecode.  First I need to make these maps for somewhat easier access.
branchMap=net["gmd_branch"]
busMap=net["gmd_bus"]

# We will be solving for bus to ground currents.  We have two matrices to 
# worry about, Y and Z.  Both are nxn where n is the number of busses.  Y
# is symettric and, for now, Z is diagonal.

numBranch=length(branchMap)
numBus=length(busMap)


branchList=collect(values(branchMap))
busList=collect(values(busMap))
busIdx=Dict([(b["index"],i) for (i,b) in enumerate(busList)])

# First we need JJ, which is the perfect earth grounding current at each
# bus location.  It is the sum of the emf on each line going into a
# substation time the y for that line

J=zeros(numBus)

mm=zeros(Int64,2*numBranch) # off diag rows
nn=zeros(Int64,2*numBranch) #off diag cols
matVals=zeros(2*numBranch) # off-diagonal values
z=-1

mmm=Array(1:numBus) # diag rows
nnn=Array(1:numBus) # diag cols
YY=zeros(numBus) # diagonal values

for i in 1:numBranch
    branch=branchList[i]
    m=find(busIdx==branch["f_bus"])
    n=find(busIdx==branch["t_bus"])
    if((m!=n) && (branch["br_status"]==1))
        J[m] = J[m] - (1.00/branch["br_r"])*branch["br_v"]
        J[n] = J[n] + (1.00/branch["br_r"])*branch["br_v"]
        
        z=z+2
        mm[z]=m
        nn[z]=n
        matVals[z]=-(1.00/branch["br_r"])
        
        mm[z+1]=n
        nn[z+1]=m
        matVals[z+1]=matVals[z]
        
        YY[m] = YY[m] + (1.00/branch["br_r"])
        YY[n] = YY[n] + (1.00/branch["br_r"])
    end
    
end

Y=sparse(vcat(mmm,mm),vcat(nnn,nn),vcat(YY,matVals))

zmm=zeros(Int64,numBus)
znn=zeros(Int64,numBus)
zmatVals=zeros(numBus)
for i in 1:numBus
    bus=busList[i]
    zmm[i]=i
    znn[i]=i
    zmatVals[i]=(1.00/bus["g_gnd"])
end
Z=sparse(zmm,znn,zmatVals)

I=speye(numBus,numBus)

MM=Y*Z

M=(I+MM)

gic=M\J
vdc=Z*gic



######

result["gic"] = Dict()
result["vdc"] = Dict()
##end

for (i,v) in enumerate(vdc)
    k = buskeys[i]
    result["vdc"]["$k"] = v
    result["gic"]["$k"] = gic[i]
end

println("Done solving $path")

opath = replace(path, ".json", "_results.json")
opath = replace(path, ".m", "_results.json")
println("Start writing $opath")
h = open(opath, "w")
JSON.print(h, result)
close(h)
println("Done writing $opath")
