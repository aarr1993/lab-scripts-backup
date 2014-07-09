# include <stdio.h>
# include <stdlib.h> // what is in here? malloc ?
# include <string.h>
//use ptrs when changing variable. Since that should not ever happen here
  // NO TRIPLE POINTERS ! wrong, when get_input func is made there will be ***
int validate(char * wig, char ** beds, int num) ;
int get_chrs (char * wig, char ** beds, int num, char *** chromosomes) ;
//void split_files (char * wig, char ** beds, int num, char ** chromosomes, int num_chrs, char **** bedfiles, char *** wigfiles) ; 

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
//  char *** bedfiles ; // list of temp names (AAH **** ptr NO) (3D)
//  char ** wigfiles ; // list of temp names
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
  {
    wig[k] = argv[1][k] ;
  }  

  for (i = 2 ; i < argc ; i++) {
    if (i % 2 == 0) 
    {
      beds[bedcount] = (char *) malloc (strlen(argv[i] + 1) * sizeof(char)) ;
      for (j = 0 ; j <= strlen(argv[i]) ; j++)
      {
        beds[bedcount][j] = argv[i][j] ;
      }
      bedcount++ ;
    }
    else
    {
      names[namecount] = (char *) malloc (strlen(argv[i] + 1) * sizeof(char)) ;
      for (j = 0 ; j <= strlen(argv[i]) ; j++)
      {
        names[namecount][j] = argv[i][j] ;
      }
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
//  split_files(wig, beds, num, chromosomes, num_chrs, &bedfiles, &wigfiles) ;  
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
  {
    if (!strstr(beds[i], ".bed"))
    {
      printf("%s is not a bed file!\n", beds[i]) ;
      return 1 ;
    }  
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
//  int tempcount = 0;
  int bedcount = 0 ;
  int wigcount = 0 ;
  char ** bedchrs ;
//  char ** wigchrs ;
  char * temp ;
  char * ptr ;
  char chr[80] ;
  char line[80] ;
  char * chrstring = "" ; // KEEP THIS OR ELSE MEM LEAK
  
  for (i = 0 ; i < num ; i++)
  {
    fp = fopen(beds[i], "r") ;
    if (fp == NULL) {
      printf("File %s was not opened.\n", beds[i]) ;
      exit(1) ;
    }  
    while (fgets(line, 80, fp) != NULL)
    {
      ptr = strtok(line, "chr") ;
//      printf("ptr : %s\n", ptr) ;
      strcpy(chr, ptr) ;
      ptr = strtok(chr, " ") ;
//      printf("chr : %s\n", chr) ;
      if (strlen(chrstring) == 0) 
      {
        chrstring = (char *) malloc ((strlen(chr) + 1) * sizeof(char) ) ;
        strcpy(chrstring, chr) ;
        bedcount ++ ;
      }
      else 
      {
        if (!strstr(chrstring, chr))
        {
          temp = (char *) malloc ((strlen(chrstring) + 1) * sizeof(char)) ;
          strcpy(temp, chrstring) ;
          free(chrstring) ;
          chrstring = (char *) malloc((strlen(temp) + 1 + strlen(chr) ) * sizeof(char)) ;
          sprintf(chrstring, "%s %s", temp, chr) ;
          free(temp) ;
          bedcount ++ ;
//          printf("chrstring: %s\n", chrstring) ;
        }
      } 
    } // while
  } // for

  bedchrs = (char **) malloc ( bedcount * sizeof(char *) ) ;

  for (j = 0 ; j < bedcount ; j++)
  {
    if (j == 0)
    {
      ptr = strtok(chrstring, " ") ;
    }
    else
    {
      ptr = strtok(NULL, " ") ;
    }
    bedchrs[j] = (char *) malloc ((strlen(ptr) + 1) * sizeof(char) ) ;
    strcpy(bedchrs[j], ptr) ;
//    printf("bedchrs[j] : [%s]\n", bedchrs[j]) ;
  }
//put chrstring in bedchrs before this 
  free(chrstring) ;
  
  fp = fopen(wig, "r") ;
  if (fp == NULL)
  {
    printf("File %s was not opened.\n", wig) ;
    exit(1) ;
  }
  while (fgets(line, 80, fp) != NULL)
  {
    if (strstr(line, "variableStep"))
    {
      ptr = strtok(line, " ") ; // SOMEHOW THIS WORKS
      ptr = strtok(NULL, " ") ;
      strcpy(chr, ptr) ;
      ptr = strtok(chr, "chrom=chr") ;
      strcpy(chr, ptr) ;
//      printf("chr : %s\n", chr) ;
//      printf("ptr : %s\n", ptr) ;
      if (strlen(chrstring) == 0) 
      {
        chrstring = (char *) malloc ((strlen(chr) + 1) * sizeof(char) ) ;
        strcpy(chrstring, chr) ;
        wigcount ++ ;
      }
      else 
      {
        if (!strstr(chrstring, chr))
        {
          temp = (char *) malloc ((strlen(chrstring) + 1) * sizeof(char)) ;
          strcpy(temp, chrstring) ;
          free(chrstring) ;
          chrstring = (char *) malloc((strlen(temp) + 1 + strlen(chr) ) * sizeof(char)) ;
          sprintf(chrstring, "%s %s", temp, chr) ;
          free(temp) ;
          wigcount ++ ;
//          printf("chrstring: %s\n", chrstring) ;
        }
      } 
    }
  }

//  wigchrs = (char **) malloc ( wigcount * sizeof(char *) ) ;
//  printf("wigcount : %d\n", wigcount) ;
//  printf("bedcount : %d\n", bedcount) ;
//  printf("chrstring : %s\n", chrstring) ;
//  for (j = 0 ; j < wigcount ; j++)
//  {
//    if (j == 0)
//    {
//      ptr = strtok(chrstring, " ") ;
//    }
//    else
//    {
//      ptr = strtok(NULL, " ") ;
//    }
//    wigchrs[j] = (char *) malloc ((strlen(ptr) + 1) * sizeof(char) ) ;
//    strcpy(wigchrs[j], ptr) ;
//    printf("wigchrs[j] : %s\n", wigchrs[j]) ;
//  }
//  sprintf(chrstring, "%s %s", chrstring, ptr) ;
//put chrstring in bedchrs before this 
//printf("chrstring : %s\n", chrstring) ;
  for (n = 0 ; n < bedcount ; n++)
  {
//    printf("bedchrs[n] : %s chrstring : %s\n", bedchrs[n], chrstring) ;
    if (strstr(chrstring, bedchrs[n]))
    {
      total++ ;     
//      printf("strstred : %s\n", bedchrs[n]) ;
    }
    else
    {
      free(bedchrs[n]) ;
      bedchrs[n] = NULL ;
//      strcpy(bedchrs[n], "0") ; // or make NULL ?
//      bedchrs[n][0] = "\0" ;
      
    }
  }  
//  printf("total = %d\n", total) ;
  *chromosomes = (char **) malloc (total * sizeof(char*)) ;
  int l ;
//  for (k = 0 ; k < total ; k++)
//  {
//    printf("LOOP\n") ;
    k = 0 ;
    for (l = 0 ; l < bedcount ; l++)
    {
//      printf("LOOP\n") ;
      if (bedchrs[l])
      {
//        printf("IF\n") ;
        if (k < total)
        {
//          printf ("IF2\n") ;
          (*chromosomes)[k] = (char *) malloc ( (strlen(bedchrs[l]) + 1) * sizeof(char) ) ;
          strcpy((*chromosomes)[k], bedchrs[l]) ;
//          printf("chromosomes[k] : %s, k : %d\n", (*chromosomes)[k], k) ;
          k++ ;
        }
      }
    }
//    printf("k : %d\n", k) ;
//    printf("HELLO\n") ;
//  } 
 
//    printf("HELLO2\n") ;
  return total ;
} // get_chrs






/*
int get_chrs (char * wig, char ** beds, int num, char *** chromosomes) 
{
  int i, j;
  FILE * fp ;
  char line[80] ;  
  char chr[80] ;
  char * chroms = "" ;
  int chr_count = 0 ;
  int total = 0 ;
  int bed_total = 0 ;
  char * temp ;
  char * ptr ;
  char ** bedchrs ;
  for (i = 0 ; i < num ; i++) 
  {
    chr_count = 0 ;
    if (strlen(chroms) != 0)
      free(chroms) ;

    fp = fopen(beds[i], "r") ;
    if (fp == NULL) 
    {
      printf("File %s was not opened.\n", beds[i]) ;
      exit(1) ; 
    }
    while (fgets(line, 80, fp) != NULL) 
    {
      ptr = strtok(line, "chr") ; 
      sprintf(chr, "%s", ptr) ; //chr is temp ONLY
        
      ptr = strtok(chr, " ") ;
//      printf("chr : %s\n", chr) ;

      if (strlen(chroms) == 0)
      {
        chroms = (char *) malloc ((strlen(chr) + 1) * sizeof(char)) ;
        strcpy(chroms, chr) ;
//        printf("chroms INIT: %s\n", chroms) ;
    
      }
      if (!strstr(chroms, chr) && strlen(chroms) > 0) 
      {
        temp = (char *) malloc ((strlen(chroms) + 1) * sizeof(char)) ;
        strcpy(temp, chroms) ;
        free(chroms) ;
        chroms = (char *) malloc ((strlen(temp) + strlen(chr) + 1) * sizeof(char)) ;
        strcpy (chroms, temp) ;
        free(temp) ;
        sprintf(chroms, "%s %s", chroms, chr) ;
        chr_count ++ ;
//        printf("chroms: %s\n", chroms) ;
      }
    }
    fclose(fp) ;
    if (i == 0) // MEMORY CORRUPTION OCCURS SOMEWHERE HERE (UNTIL int wig_total)
      bedchrs = (char **) malloc ((chr_count + 1) * sizeof(char*)) ; 
      // *chromosomes = (char **) malloc ((chr_count - 1) * sizeof(char*)) ; 
    for (j = 0 ; j <= chr_count ; j ++)
    {
      if (j == 0)
        ptr = strtok(chroms, " ") ;
      else
        ptr = strtok(NULL, " ") ; 

      //(*chromosomes)[total] = (char *) malloc ((strlen(ptr) + 1) * sizeof (char) ) ;
      bedchrs[bed_total] = (char *) malloc ((strlen(ptr) + 1) * sizeof (char) ) ;
      //strcpy((*chromosomes)[total], ptr) ;
      strcpy(bedchrs[bed_total], ptr) ;
      bed_total++ ;
//      printf ("%s\n", ptr) ;
//      printf("%s\n", (*chromosomes)[j]) ;
    }
  }
  int wig_total = 0;
  char ** wigchrs ; 

  chr_count = 0 ;
  if (strlen(chroms) != 0)
    free(chroms) ;

  fp = fopen(wig, "r") ;
  if (fp == NULL) 
  {
    printf("File %s was not opened.\n", wig) ;
    exit(1) ; 
  }
  while (fgets(line, 80, fp) != NULL) 
  {
    if (strstr(line, "variableStep")) 
    {
      ptr = strtok(line, " ") ;              // FIX THIS MESS
//      ptr = strtok(NULL, "chrom=chr") ;
//      ptr = strtok(NULL, "r") ;
      ptr = strtok(NULL, "=") ;
      ptr = strtok(NULL, " ") ;
 //     ptr = strtok(NULL, "ch") ;
      sprintf(chr, "%s", ptr) ;
      ptr = strtok(chr, "chr") ;
//      printf("ptr : %s\n", ptr) ;
      sprintf(chr, "%s", ptr) ;
      if (strlen(chroms) == 0)
      {
        chroms = (char *) malloc ((strlen(chr) + 1) * sizeof(char)) ;
        strcpy(chroms, chr) ;
//        printf("chroms INIT: %s\n", chroms) ;
      }
      if (!strstr(chroms, chr) && strlen(chroms) > 0) 
      {
        temp = (char *) malloc ((strlen(chroms) + 1) * sizeof(char)) ;
        strcpy(temp, chroms) ;
        free(chroms) ;
        chroms = (char *) malloc ((strlen(temp) + strlen(chr) + 1) * sizeof(char)) ;
        strcpy (chroms, temp) ;
        free(temp) ;
        sprintf(chroms, "%s %s", chroms, chr) ;
        chr_count ++ ;
        printf("chroms: %s\n", chroms) ; // out ok here?
      }
    }
  }
  fclose(fp) ; // gives free segfault ????
  printf("chroms: %s", chroms) ; // v weird here
  wigchrs = (char **) malloc ((chr_count - 1) * sizeof(char*)) ;
   // *chromosomes = (char **) malloc ((chr_count - 1) * sizeof(char*)) ; 
  for (j = 0 ; j <= chr_count ; j ++)
  {
    if (j == 0)
      ptr = strtok(chroms, " ") ;

    else
      ptr = strtok(NULL, " ") ; 
    //(*chromosomes)[total] = (char *) malloc ((strlen(ptr) + 1) * sizeof (char) ) ;
    wigchrs[wig_total] = (char *) malloc ((strlen(ptr) + 1) * sizeof (char) ) ;
    //strcpy((*chromosomes)[total], ptr) ;
    strcpy(wigchrs[wig_total], ptr) ;
    wig_total++ ;
    printf("%s\n", wigchrs[wig_total]) ; // V Weird output
//    printf ("%s\n", ptr) ;
//    printf("%s\n", (*chromosomes)[j]) ;
  }

  return total ; // drat only had beds' chrs -- need to compare to wig's!
} // get_chrs ()

void split_files (char * wig, char ** beds, int num, char ** chromosomes, int chr_total, char **** bedfiles, char *** wigfiles) 
{
  

} // split_files () 
*/

