#python

import numpy as np
import argparse
import torch
from nnet3.xvector.model_tdnn import *
from spectral_scoring.kaldi_io import *
import os,errno
import pickle as pkl
from scipy.special import expit,logit
from models_train_ssc_plda import weight_initialization
from spectral_scoring.run_spectralclustering import do_spectral_clustering

device="cpu"
import warnings
warnings.filterwarnings("ignore")
###########
# ArgParser
def arguments():
    parser = argparse.ArgumentParser()
    # Dataset
    parser.add_argument('--out_path', type=str, required=True)
    parser.add_argument('--rttm_gndpath', type=str, default=None)
    #Xvector 
    parser.add_argument('--featspath', type=str, default=None,help="segmented mfccs path")
    parser.add_argument('--feats_file',type=str,default=None)
    parser.add_argument('--reco2utt_list', type=str, default=None)
    parser.add_argument('--segments_list', type=str, default=None)
    parser.add_argument('--dataset_str', type=str, default=None)
    parser.add_argument('--xvec_model_weight_path',type=str,default=None)
    parser.add_argument('--xvec_dim',type=int,default=512)
    
    #pldamodel
    parser.add_argument('--pldamodel',type=str,default=None)
    parser.add_argument('--target_energy',type=float,default=0.3)
    # for parallel processing
    parser.add_argument('--splitlist',type=str,default=None)

    # output xvectors 
    parser.add_argument('--xvecpath_out', type=str, default=None,help='store model xvectors')

    # spectral clustering 
    parser.add_argument('--threshold',type=float,default=0.5)
    # python path
    parser.add_argument('--which_python',type=str,default='python')
    args = parser.parse_args()
    return args

args = arguments()

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else: raise

def unique(arr, return_ind=False):
    if return_ind:
        k = 0
        d = dict()
        uniques = np.empty(arr.size, dtype=arr.dtype)
        indexes = np.empty(arr.size, dtype='i')
        for i, a in enumerate(arr):
            if a in d:
                indexes[i] = d[a]
            else:
                indexes[i] = k
                uniques[k] = a
                d[a] = k
                k += 1
        return uniques[:k], indexes
    else:
        _, idx = np.unique(arr, return_index=True)
        return arr[np.sort(idx)]

def write_results_dict(fname, output_file, results_dict, reco2utt):
        """Writes the results in label file"""
        f = fname
        output_label = open(output_file+'/'+f+'.labels','w')

        hypothesis = results_dict[f]
        meeting_name = f
        reco = f
        utts = reco2utt.rstrip().split()
        if reco == meeting_name:
            for j,utt in enumerate(utts):
                towrite = utt +' '+str(hypothesis[j])+'\n'
                output_label.writelines(towrite)
        output_label.close()

        rttm_channel=1
        segmentsfile = args.segments_list+'/'+f+'.segments'
        python = args.which_python
        
        kaldi_recipe_path="local/"
        cmd = '{} {}/diarization/make_rttm.py --rttm-channel  {} {} {}/{}.labels {}/{}.rttm' .format(python,kaldi_recipe_path,rttm_channel, segmentsfile,output_file,f,output_file,f)        
        os.system(cmd)

def compute_score(rttm_gndfile,rttm_newfile,outpath,overlap):
      fold_local='services/'
      scorecode='score.py -r '
    #   bp()
      # print('--------------------------------------------------')
      if not overlap:
          cmd = '{} {}/dscore-master/{}{} --ignore_overlaps --collar 0.25 -s {} > {}.txt 2> err.txt'.format(args.which_python,fold_local,scorecode,rttm_gndfile,rttm_newfile,outpath)
          # cmd=args.which_python +' '+ fold_local + 'dscore-master/' + scorecode + rttm_gndfile + ' --ignore_overlaps --collar 0.25 -s ' + rttm_newfile + ' > ' + outpath + '.txt'
          os.system(cmd)
          bashCommand="cat {}.txt | grep OVERALL |awk '{{print $4}}'".format(outpath)
      
      else:
          cmd = '{} {}/dscore-master/{}{} -s {} > {}_overlap.txt 2> err.txt'.format(args.which_python,fold_local,scorecode,rttm_gndfile,rttm_newfile,outpath)
          # cmd=args.which_python + ' '+ fold_local + 'dscore-master/' + scorecode + rttm_gndfile + ' -s ' + rttm_newfile + ' > ' + outpath + '.txt'
          os.system(cmd)
          bashCommand="cat {}_overlap.txt | grep OVERALL |awk '{{print $4}}'".format(outpath)
      
      # print('----------------------------------------------------')
      # subprocess.check_call(cmd,stderr=subprocess.STDOUT)
      # print('scoring ',rttm_gndfile)
      
      output=subprocess.check_output(bashCommand,shell=True)
      # output=subprocess.check_output(bashCommand,stderr=subprocess.DEVNULL)
      return float(output.decode('utf-8').rstrip())



def load_data_plda_feats(filename,X,pldascore,device='cpu',scale=10):
    # scale = 1
    pldamodel = pkl.load(open(args.pldamodel,'rb'))
    if os.path.isfile(pldascore):
        with open(pldascore,'rb') as fb:
            A = pkl.load(fb)
    else:
        # features = torch.FloatTensor(X).to(device)
        features = X.to(device)
        xvecD = features.shape[1]
        pca_dim = 30
        inpdata = features[np.newaxis]
        net_init = weight_initialization(pldamodel,dimension=xvecD,pca_dimension=pca_dim,device=device)
        model_init = net_init.to(device)
        affinity_init,_,_ = model_init.compute_plda_affinity_matrix(pldamodel,inpdata,target=1) # original filewise PCA transform
        output_model = affinity_init.detach().cpu().numpy()[0]
        # bp()
        A = expit(output_model*scale)

        with open(pldascore,'wb') as fb:
            pkl.dump(A,fb)

    return  A


class diarization():
    def __init__(self):
        ##################
        # Data Preparation
        self.featsdict = {}
        with open(args.featspath) as fpath:
            for line in fpath: 
                key, value = line.split(" ",1)
                self.featsdict[key] = value.rsplit()[0]

        reco2utt_list = open(args.reco2utt_list).readlines()
        self.reco2utt_dict = {}
        for line in reco2utt_list:
            rec, utt = line.split(" ",1)
            self.reco2utt_dict[rec] = utt

    def load_mfcc_feats_nosilence(self,filename,featsdict,reco2utt,device='cpu',featsbatch=0):
        # load the data: x, tx, allx, graph
        segments_xvec = f'{args.segments_list}/{filename}.segments' 
        utts = reco2utt.split() # all utterances in a recording stored as dict
        seg_xvec = np.genfromtxt(segments_xvec,dtype=float)[:,2:]
        diff_xvec = seg_xvec[:,1]-seg_xvec[:,0]
        diff_xvec = np.round(diff_xvec,2)
        # idx_xvec = np.where(diff_xvec>=1.5)[0]  # discard segments <=1.5sec for training
        idx_xvec = np.where(diff_xvec>=0.0)[0] 
        subsample = 1
        idx_xvec = idx_xvec[::subsample]
        
        if not featsbatch:
            features = []
            for utt in utts:
                val = featsdict[utt]
                features.append(read_mat(val))
            features = np.concatenate(features,axis=0)
            features = torch.FloatTensor(features).to(device)
        else:
            win = 150
            features = []
            utts = np.asarray(utts)
            for uid,utt in enumerate(utts[idx_xvec]):
                val = featsdict[utt]
                valsplit = val.split('[')[0]
                start = int(val.split('[')[1].split(':')[0])
                end =  int(val.split('[')[1].split(':')[1].split(']')[0])
                if end+1-start >= win:
                    feats = read_mat(valsplit)[start:start+win]
                    features.append(feats)
                else:
                    diff = end+1-start
                    # print('diff short:',diff)
                    low = int(np.floor((win-diff)/2))
                    high = int(np.ceil((win-diff)/2))
                    
                    feats = read_mat(valsplit)[start:end+1]
                    # featspad = np.pad(feats,((low,high),(0,0)),'symmetric')
                    featspad = np.pad(feats,((0,win-diff),(0,0)),'wrap')
                    if len(featspad) > win:
                        print(f'batchsize greater than {win}')
                    features.append(featspad)
                #     print(start,end,end+1-start,utt,round(seg_xvec[uid,1]-seg_xvec[uid,0],2),uid)
        
        features = np.array(features)
        return features
        

    def extract_xvectors(self,recid,model):
        # extract xvectors
        if os.path.isfile(f'{args.xvecpath_out}/{recid}.npy'):
            xvec_features = np.load(f'{args.xvecpath_out}/{recid}.npy')
            mfcc_xvec_features = torch.FloatTensor(xvec_features).to(device)
        else:
            reco2utt = self.reco2utt_dict[recid]
            
            mfcc_feats= self.load_mfcc_feats_nosilence(recid,self.featsdict,reco2utt,featsbatch=1)
            mfcc_features = torch.FloatTensor(mfcc_feats).to(device)
            print('mfcc: ',mfcc_features.shape)
            mfcc_xvec_features = model.extract(mfcc_features)
            xvec_features = mfcc_xvec_features.cpu().detach().numpy()

            np.save(f'{args.xvecpath_out}/{recid}.npy',xvec_features)
            print(f'{args.xvecpath_out}/{recid}.npy')
        return mfcc_xvec_features
    
    def plda_scores(self,xvectors,recid):
        #compute PLDA scores
        scale=10
        pldascorepath = args.out_path
        if scale> 1:
            scale_str =f'_scale{scale}'
        else:
            scale_str=''

        pldascorepath = f'{pldascorepath}/plda_scores{scale_str}'
        pldascore = f'{pldascorepath}/{recid}.pkl'
        cmd = f'mkdir -p {pldascorepath}'
        os.system(cmd)
        distance_matrix = load_data_plda_feats(recid,xvectors,pldascore,scale=scale)
        return distance_matrix

    def spectral_clustering_threshold(self,f,distance_matrix,reco2utt,threshold=None,scoretype='laplacian',flag=1):
        print('Spectral Clustering')
        # overlap =1
        results_dict = defaultdict(np.array)
        # threshold = None
        labelfull=np.arange(distance_matrix.shape[0])
        clusterlen=[1]*len(labelfull)    
        
        print(f'threshold:{threshold}')
        if flag:
            minK = 1
            maxK = 10
            th = threshold
        # custom_dist='cosine',scoretype='laplacian',
        if scoretype is None:
            # custom_dist='cosine'
            labelfull = do_spectral_clustering(distance_matrix,
                                                gauss_blur=0.1,
                                                p_percentile=0.95,
                                                minclusters=minK,
                                                maxclusters=maxK,
                                                truek=4,custom_dist='cosine',
                                                stop_eigenvalue=th)
        else:
            # custom_dist='cosine',scoretype='laplacian',
            labelfull = do_spectral_clustering(distance_matrix,
                                                gauss_blur=0.1,
                                                p_percentile=0.95,
                                                minclusters=minK,
                                                maxclusters=maxK,
                                                truek=4,
                                                scoretype=scoretype,
                                                custom_dist='cosine',
                                                stop_eigenvalue=th)
    
        uniq_labels,labelfull=unique(labelfull,True)

        labelfull = labelfull.reshape(-1,1)

        n_clusters=len(uniq_labels)
        clusterlen = []
        for lab in uniq_labels:
            clusterlen.append(len(np.where(labelfull==lab)[0]))

        print('clusterlen:',clusterlen,' n_clusters:',n_clusters)
        results_dict[f]=labelfull.reshape(-1,)

        out_file=args.out_path+'/'+'per_file_rttm/'

        mkdir_p(out_file)
        outpath=out_file +'/'+f
        rttm_newfile=out_file+'/'+f+'.rttm'   
 
        write_results_dict(f, out_file, results_dict, reco2utt)

        if args.rttm_gndpath is not None:
            rttm_gndfile = f'{args.rttm_gndpath}/{f}.rttm'
            if os.path.isfile(rttm_gndfile):
                der = compute_score(rttm_gndfile,rttm_newfile,outpath,0)
                overlap_der = compute_score(rttm_gndfile,rttm_newfile,outpath,1)
                print("\n%s  overlap DER: %.2f" % (f, overlap_der))
                print("\n%s DER: %.2f" % (f, der))
    def test(self,recid,model):
        #    call all the steps
        #    extract_xvectors
        #    plda_scores
        #    clustering 
        
        xvectors = self.extract_xvectors(recid,model)
        scores = self.plda_scores(xvectors,recid)
        reco2utt = self.reco2utt_dict[recid]
        self.spectral_clustering_threshold(recid,scores,reco2utt,threshold=args.threshold)



model = e2e_diarization_nosilence(xvecmodelpath=args.xvec_model_weight_path,
               device = device
               )
model = model.to(device)
model.eval()

demo = diarization()
if args.splitlist is not None:
    filelist = np.genfromtxt(args.splitlist,dtype=float).astype(int).reshape(-1,)
    recsublist = np.genfromtxt(args.feats_file,dtype=str).reshape(-1,)[filelist]
    for recid in recsublist:
        # demo.extract_xvectors(recid,model)
        demo.test(recid,model)
else:
   recid = args.feats_file
#    demo.extract_xvectors(recid,model)
   demo.test(recid,model)