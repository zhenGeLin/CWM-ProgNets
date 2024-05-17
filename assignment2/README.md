# Plotting Figures


1. Save your data a space-delimied format, such as in the example `test.data` file.

The first column contains x-axis values (e.g., time). The second column contains y-axis values (e.g., packet drops).

2. Using a text editor, modify paramters in `plot.py`

The parameters to be modified are: 

- filename - name of the data file.
- label – label to be used in the legend, e.g., “iperf2” or “iperf3”. 
- xlabel – x-axis label 
- ylabel – y-axis label 
- title – title of the plotted graph 
- fig\_name – name of the saved file 

3. To plot your figure, run the python script:
```
python3 plot.py
```
