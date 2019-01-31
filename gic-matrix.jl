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
%I assume the branchListStruct and busListStruct are snatched directly from
%jsondecode.  First I need to make these maps for somewhat easier access.
branchMap=GICCalc.JSONStructToMap(branchListStruct);
busMap=GICCalc.JSONStructToMap(busListStruct);

%We will be solving for bus to ground currents.  We have two matrices to 
%worry about, Y and Z.  Both are nxn where n is the number of busses.  Y
%is symettric and, for now, Z is diagonal.

numBranch=length(branchMap);
numBus=length(busMap);


branchList=values(branchMap)';
busList=values(busMap)';
busIdx=cell2mat(keys(busMap))';

%First we need JJ, which is the perfect earth grounding current at each
%bus location.  It is the sum of the emf on each line going into a
%substation time the y for that line

J=zeros(numBus,1);

mm=zeros(2*numBranch,1); % off diag rows
nn=zeros(2*numBranch,1); %off diag cols
matVals=zeros(2*numBranch,1); % off-diagonal values
z=-1;

mmm=(1:numBus)'; % diag rows
nnn=(1:numBus)'; % diag cols
YY=zeros(numBus,1); % diagonal values

for i=1:numBranch
    branch=branchList{i};
    m=find(busIdx==branch.f_bus,1);
    n=find(busIdx==branch.t_bus,1);
    if((m~=n) && (branch.br_status==1))
        J(m) = J(m) - (1.00/branch.br_r)*branch.br_v;
        J(n) = J(n) + (1.00/branch.br_r)*branch.br_v;
        
        z=z+2;
        mm(z)=m;
        nn(z)=n;
        matVals(z)=-(1.00/branch.br_r);
        
        mm(z+1)=n;
        nn(z+1)=m;
        matVals(z+1)=matVals(z);
        
        YY(m) = YY(m) + (1.00/branch.br_r);
        YY(n) = YY(n) + (1.00/branch.br_r);
    end
    
end

Y=sparse([mmm;mm],[nnn;nn],[YY;matVals]);

zmm=zeros(numBus,1);
znn=zeros(numBus,1);
zmatVals=zeros(numBus,1);
for i=1:numBus
    bus=busList{i};
    zmm(i)=i;
    znn(i)=i;
    zmatVals(i)=(1.00/bus.g_gnd);
end
Z=sparse(zmm,znn,zmatVals);

I=speye(numBus,numBus);

MM=Y*Z;

M=(I+MM);

gic=M\J;
vdc=Z*gic;

end


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
