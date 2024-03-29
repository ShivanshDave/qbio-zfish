import h5py
import sys
h5file = sys.argv[1]

f = h5py.File(h5file, 'r')

dataset = f['df_with_missing/table']

outputfile = h5file.split("DeepCut")[0] + ".mp4.dat"

with open(outputfile, 'a') as outf:

    outf.write("# DeepLabCut data points \n# 1:frame 2:xhead 3:yhead 4:xtail 5:ytail\n")
    
    for d in dataset:
        
        if d[0]>5: outf.write("{0} {1} {2} {3} {4}\n".format(d[0],d[1][0],d[1][1],d[1][3],d[1][4]))
        

