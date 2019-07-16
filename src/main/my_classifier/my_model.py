#!/usr/bin/python3


import sys, getopt
import subprocess
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
import numpy as np
import pickle


def main(argv):
   inputfile = ''
   outputfile = 'predicted_classes'
   try:
      opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
   except getopt.GetoptError:
      print('./my_model.py -i <input_dataset_filename> -o <output_label_filename>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print('./my_model.py -i <input_dataset_filename> -o <output_label_filename>')
         sys.exit()
      elif opt in ("-i", "--ifile"):
         inputfile = arg
      elif opt in ("-o", "--ofile"):
         outputfile = arg
            
   data_to_test = pd.read_csv(inputfile)
   loaded_model = pickle.load(open('my_model.sav', 'rb'))
   y_pred = loaded_model.predict(data_to_test)
   np.savetxt(outputfile, y_pred, delimiter=',')
   print("Predicted classes: ", y_pred)
   
if __name__ == "__main__":
   main(sys.argv[1:])
