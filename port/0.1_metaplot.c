// FINNISHED get_chrs
//Most comments deleted

# include <stdio.h>
# include <stdlib.h> // what is in here? malloc ?
# include <string.h>
//use ptrs when changing variable. Since that should not ever happen here
  // NO TRIPLE POINTERS ! wrong, when get_input func is made there will be ***
int validate(char * wig, char ** beds, int num) ;
int get_chrs (char * wig, char ** beds, int num, char *** chromosomes) ;
void split_files (char * wig, char ** beds, int num_beds, char ** chromosomes, int num_chrs, char **** bedfiles, char *** wigfiles) ; 

int main (int argc, char * argv[]) 
{

  if (argc < 3) 
  {
    printf("usage : %s wig bedfile1 name1 bedfile1 name2 ...\n", argv[0]) ;
    return 1 ;
  }

  char ** beds ; // array of char arrays 
  char ** names ; // same
  char * wig ; // array of chars (string)
  int i, j, k ; // count variables
  int num = ( argc - 1 ) / 2 ; // num of beds and names
  char ** chromosomes ; // common chrs
  int num_chrs ;
  char *** bedfiles ; // list of temp names (AAH **** ptr NO) (3D)
  char ** wigfiles ; // list of temp names
  // all this just to get filenames! make into seperate function with ***
  // why am I malloc - ing everything instead of char array[80] ? 
    // don't want filename char limits
  // remember to free() at end

  // DO NOT TOUCH THIS BLOCK !!! All segfaults solved <-------
  wig = (char *) malloc ( (strlen(argv[1]) + 1) * sizeof(char) ) ;
  beds = (char **) malloc (num * sizeof(char *)) ;
  names = (char **) malloc (num  * sizeof(char *)) ;
  int bedcount = 0;
  int namecount = 0 ;
  for (k = 0 ; k <= strlen(argv[1]) ; k++) 
    wig[k] = argv[1][k] ;

  for (i = 2 ; i < argc ; i++) {
    if (i % 2 == 0) 
    {
      beds[bedcount] = (char *) malloc (strlen(argv[i] + 1) * sizeof(char)) ;
      for (j = 0 ; j <= strlen(argv[i]) ; j++)
        beds[bedcount][j] = argv[i][j] ;
      bedcount++ ;
    }
    else
    {
      names[namecount] = (char *) malloc (strlen(argv[i] + 1) * sizeof(char)) ;
      for (j = 0 ; j <= strlen(argv[i]) ; j++)
        names[namecount][j] = argv[i][j] ;
      namecount ++ ;
    }
  }
  if (bedcount != namecount) 
  {
    printf("Error! Num of beds != Num of names! Bed : %d, Name %d\n", bedcount, namecount) ;
    printf("Exiting\n") ;
    return 1 ;
  }
  // got filenames
  if (validate(wig, beds, num)) 
  {
    printf ("Exiting\n") ;
    return 1 ;
  }
  // -----------> DO NOT TOUCH

  // should I do lowmem version?
  num_chrs = get_chrs(wig, beds, num, &chromosomes) ;
  split_files(wig, beds, num, chromosomes, num_chrs, &bedfiles, &wigfiles) ;  
  // there has to be a better way than this 
  // debug print statements
/*
  printf("wig : %s\n", wig) ;
  int n ;
  for (n = 0 ; n < num ; n ++) 
  {
    printf("bed %d : %s name : %s\n", n, beds[n], names[n]) ;
  }
*/
  return 0 ;
} // main ()

int validate(char * wig, char ** beds, int num)
{
  int i ;

  if (!strstr(wig, ".wig"))
  {
    printf("%s is not a wig file!\n", wig) ;
    return 1 ; 
  }  

  for (i = 0 ; i < num ; i++)
    if (!strstr(beds[i], ".bed"))
    {
      printf("%s is not a bed file!\n", beds[i]) ;
      return 1 ;
    }  
  
  return 0 ;
} // validate () 

int get_chrs (char * wig, char ** beds, int num, char *** chromosomes) 
{
  FILE * fp ;
  int i;
  int j ;
  int n ;
  int k ;
  int total = 0 ;
  int bedcount = 0 ;
  int wigcount = 0 ;
  char ** bedchrs ;
  char * temp ;
  char * ptr ;
  char chr[80] ;
  char line[80] ;
  char * chrstring = "" ; // KEEP THIS OR ELSE MEM LEAK
  
  for (i = 0 ; i < num ; i++)
  {
    fp = fopen(beds[i], "r") ;
    if (fp == NULL) 
    {
      printf("File %s was not opened.\n", beds[i]) ;
      exit(1) ;
    }  
    while (fgets(line, 80, fp) != NULL)
    {
      ptr = strtok(line, "chr") ;
      strcpy(chr, ptr) ;
      ptr = strtok(chr, " ") ;
      if (strlen(chrstring) == 0) 
      {
        chrstring = (char *) malloc ((strlen(chr) + 1) * sizeof(char) ) ;
        strcpy(chrstring, chr) ;
        bedcount ++ ;
      }
      else 
        if (!strstr(chrstring, chr))
        {
          temp = (char *) malloc ((strlen(chrstring) + 1) * sizeof(char)) ;
          strcpy(temp, chrstring) ;
          free(chrstring) ;
          chrstring = (char *) malloc((strlen(temp) + 1 + strlen(chr) ) * sizeof(char)) ;
          sprintf(chrstring, "%s %s", temp, chr) ;
          free(temp) ;
          bedcount ++ ;
        }
    } // while
    fclose(fp) ;
  } // for

  bedchrs = (char **) malloc ( bedcount * sizeof(char *) ) ;

  for (j = 0 ; j < bedcount ; j++)
  {
    if (j == 0)
      ptr = strtok(chrstring, " ") ;
    else
      ptr = strtok(NULL, " ") ;
    bedchrs[j] = (char *) malloc ((strlen(ptr) + 1) * sizeof(char) ) ;
    strcpy(bedchrs[j], ptr) ;
  }
  free(chrstring) ;
  fp = fopen(wig, "r") ;
  if (fp == NULL)
  {
    printf("File %s was not opened.\n", wig) ;
    exit(1) ;
  }
  while (fgets(line, 80, fp) != NULL)
    if (strstr(line, "variableStep"))
    {
      ptr = strtok(line, " ") ; // SOMEHOW THIS WORKS
      ptr = strtok(NULL, " ") ;
      strcpy(chr, ptr) ;
      ptr = strtok(chr, "chrom=chr") ;
      strcpy(chr, ptr) ;
      if (strlen(chrstring) == 0) 
      {
        chrstring = (char *) malloc ((strlen(chr) + 1) * sizeof(char) ) ;
        strcpy(chrstring, chr) ;
        wigcount ++ ;
      }
      else 
        if (!strstr(chrstring, chr))
        {
          temp = (char *) malloc ((strlen(chrstring) + 1) * sizeof(char)) ;
          strcpy(temp, chrstring) ;
          free(chrstring) ;
          chrstring = (char *) malloc((strlen(temp) + 1 + strlen(chr) ) * sizeof(char)) ;
          sprintf(chrstring, "%s %s", temp, chr) ;
          free(temp) ;
          wigcount ++ ;
        }
    }
  fclose(fp) ;

  for (n = 0 ; n < bedcount ; n++)
  {
    if (strstr(chrstring, bedchrs[n]))
      total++ ;     
    else
    {
      free(bedchrs[n]) ;
      bedchrs[n] = NULL ;
    }
  }  
  *chromosomes = (char **) malloc (total * sizeof(char*)) ;
  int l ;
    k = 0 ;
    for (l = 0 ; l < bedcount ; l++)
      if (bedchrs[l])
        if (k < total)
        {
          (*chromosomes)[k] = (char *) malloc ( (strlen(bedchrs[l]) + 1) * sizeof(char) ) ;
          strcpy((*chromosomes)[k], bedchrs[l]) ;
          k++ ;
        }
  return total ;
} // get_chrs

void split_files (char * wig, char ** beds, int num_beds, char ** chromosomes, int num_chrs, char **** bedfiles, char *** wigfiles) 
{
//bedfiles data stucture
//char **** > ptr to ***
// *** > num_beds elements 
// ** > array of filenames for that input bed
// * > char array of filename
// everything malloced because C
//wigfiles data structure
//char *** > ptr to **
// ** > array of filenames for wig
// * > char array of filename
// malloced again (in loops) 
// wait, num filenames is just num_chrs. Initialize!
  int i ;
  int j ;
  int k ;
  int n ;
  int m ;
  int o ;
  FILE * fp ;
  FILE * tempfp ;
  char filename[80] ;
  char line[80] ;
  char * ptr ;
  char chr[80] ;
// initialize all temp filenames
  *bedfiles = (char ***) malloc (num_beds * sizeof(char **)) ;
  for (i = 0 ; i < num_beds ; i++)
  {
    (*bedfiles)[i] = (char **) malloc (num_chrs * sizeof(char *)) ;
    for (j = 0 ; j < num_chrs ; j++)
    {
      sprintf(filename, "bed_%d_%s.tmp", i, chromosomes[j]) ;
      (*bedfiles)[i][j] = (char *) malloc ((strlen(filename) + 1) * sizeof(char)) ;
      strcpy((*bedfiles)[i][j], filename) ;
//    printf("filename : %s\n", (*bedfiles)[i][j]) ;
    }
  }
  *wigfiles = (char **) malloc (num_chrs * sizeof(char *)) ;
  for (k = 0 ; k < num_chrs ; k++)
  {
    sprintf(filename, "wig_%s.tmp", chromosomes[k]) ;
    (*wigfiles)[k] = (char *) malloc ((strlen(filename) + 1) * sizeof(char)) ;
    strcpy ((*wigfiles)[k], filename) ;
//  printf("wig filename : %s\n", (*wigfiles)[k]) ;
  }
// end initialize --> make into separate func?

  for (n = 0 ; n < num_beds ; n++)
  {
    fp = fopen(beds[n], "r") ;
    if (fp == NULL)
    {
      printf("Could not open %s\n", beds[n]) ;
      exit(1) ;
    }
   //this loop will cause so many problems
    while (fgets(line, 80, fp) != NULL)
    {
      ptr = strtok(line, "chr") ;
      strcpy(chr, ptr) ;
      ptr = strtok(chr, " ") ;
      for (m = 0 ; m < num_chrs ; m++)
        if (!strcmp(chromosomes[m], chr)) // ! b/c strcmp returns 0 if match  
        {
          tempfp = fopen((*bedfiles)[n][m], "a") ; // see below comment FIX
          fprintf(tempfp, "%s", line) ;
          fclose(tempfp) ; // terrible way of doing this
        }
    }
    fclose(fp) ;
  } 
  int found = 0 ;
  char linecopy[80] ;
  fp = fopen(wig, "r") ;
  tempfp = NULL ;
  while (fgets(line, 80, fp) != NULL)
  {
    strcpy(linecopy, line) ; // line gets destroyed by strtok
    if (strstr(line, "variableStep"))
    {
      if (tempfp != NULL) 
        fclose(tempfp) ;
      found = 0 ;
      ptr = strtok(line, " ") ; // SOMEHOW THIS WORKS
      ptr = strtok(NULL, " ") ;
      strcpy(chr, ptr) ;
      ptr = strtok(chr, "chrom=chr") ;
      strcpy(chr, ptr) ;
      for ( o = 0 ; o < num_chrs ; o ++)
        if (strcmp(chromosomes[o], chr)) 
        {
          tempfp = fopen((*wigfiles)[o], "a") ; 
          fprintf(tempfp, "%s", linecopy) ; 
          found = 1 ;
        }
    }
    else
     if (found == 1)
      fprintf(tempfp, "%s", linecopy) ;
  }


  fclose(fp) ;
} // split_files () 





