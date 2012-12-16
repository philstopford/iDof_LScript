@version 2.0
@warnings
@script image
@name "iDof Post Blur"

var scenejustloaded;
var ifo;
var kernel;
var quality_setting;
var total_pixels;
var max_kernel;
var pixel_red;
var pixel_green;
var pixel_blue;
var pixel_rgb;
var pixel_alpha;
var p_id;
var put_red;
var put_green;
var put_blue;
var put_rgb;
var put_alpha;
var plug_name = "iDof Post Blur";

create
{
	setdesc(plug_name);
	scenejustloaded = 0;
	kernel = 1;
	max_kernel = 25;
	quality_setting = 1;
}

destroy
{
}

flags
{
	return (RED,GREEN,BLUE,ALPHA,DEPTH);
}

process: ifo
{
	if(scenejustloaded == 1)
	{
		variable_fixing();
	}
    i = 1;
    j = 1;
    total_pixels = ifo.width * ifo.height;
    pixel_rgb[1] = <255,255,255>;
    //pixel_alpha[1] = 255;
    pixel_rgb[total_pixels] = <255,255,255>;
    //pixel_alpha[total_pixels] = 255;

    //set up the arrays for storing pixel information
    pixel_red[1] = 1;
    pixel_green[1] = 1;
    pixel_blue[1] = 1;
    //pixel_alpha[1] = 1;
    p_id = 1;
  
	if(runningUnder() != SCREAMERNET)
	{
		moninit(ifo.height);
	}
	for(i = 1;i < ifo.height;i++)	//vert loop
	{
		for(j = 1;j < ifo.width;j++)	//horiz loop
		{
			sample_for_current_pixel(ifo,i,j,quality_setting);
			//assign the returned values to the current marked pixel id
			pixel_rgb[p_id] = <put_red,put_green,put_blue>;
			//pixel_alpha[p_id] = put_alpha;
			p_id++;
		}
		if(runningUnder() != SCREAMERNET)
		{
			if(monstep())
				return;
		}
	}
	if(runningUnder() != SCREAMERNET)
	{
		monend();
	}
    
	p_id = 1;
	if(runningUnder() != SCREAMERNET)
	{
		moninit(ifo.height);
	}
	for(i = 1;i < ifo.height;i++)	//vert loop
	{
		for(j = 1;j < ifo.width;j++)	//horiz loop
		{
			if(ifo.alpha[j,i] > 0 && ifo.alpha[j,i] < 0.4)
			{
				alpha_multiplier = ifo.alpha[j,i];
				put_rgb[1] = ((1-alpha_multiplier)*ifo.red[j,i]) + (alpha_multiplier*pixel_rgb[p_id].x);
				put_rgb[2] = ((1-alpha_multiplier)*ifo.green[j,i]) + (alpha_multiplier*pixel_rgb[p_id].y);
				put_rgb[3] = ((1-alpha_multiplier)*ifo.blue[j,i]) + (alpha_multiplier*pixel_rgb[p_id].z);
				ifo.red[j,i] = put_rgb[1];
				ifo.green[j,i] = put_rgb[2];
				ifo.blue[j,i] = put_rgb[3];
			} else {
				put_rgb[1] = pixel_rgb[p_id].x;
				put_rgb[2] = pixel_rgb[p_id].y;
				put_rgb[3] = pixel_rgb[p_id].z;
				ifo.red[j,i] = put_rgb[1];
				ifo.green[j,i] = put_rgb[2];
				ifo.blue[j,i] = put_rgb[3];
			}

			p_id++;                
		}
		if(runningUnder() != SCREAMERNET)
		{
			if(monstep())
				return;
		}
	}
	if(runningUnder() != SCREAMERNET)
	{
		monend();
	}
	i = 1;
	j = 1;
}

options
{
	if(!reqbegin("iDof 3.2 Blur"))
		return;
	reqsize(240,190);
	
	i1 = ctlimage("idof_3_blur.tga",3,2,,234,63);   
	c1 = ctlinteger("Select Blur Amount",kernel);
	c2 = ctlpopup("Select Quality",quality_setting,@"Preview","Final"@);
	ctlposition(c2,5,100);
	
	if(reqpost())
	{
		kernel = getvalue(c1);
		quality_setting = getvalue(c2);
		
		if(kernel < 1)
		{
			info("Error: Must be between 1 and " + max_kernel +  ".  Value has been set to 1.");
			kernel = 1;
		}
		if(kernel > max_kernel)
		{
			info("Info: A blur greater than " + max_kernel +  " could yield LONG render times.  You might want to change this before rendering.");
		}
		
		plug_name_base = "iDof Post Blur:  ";
		plug_name_kernel = "amount= " + kernel;
		if(quality_setting == 1)
		{
			plug_name_quality = "  quality= Preview";
		}
		else
		{
			plug_name_quality = "  quality= Final";
		}
		plug_name = plug_name_base + plug_name_kernel + plug_name_quality;
		setdesc(plug_name);
	}
}

save: what,io
{
	if(what == SCENEMODE)
	{
		io.writeln(kernel);
		io.writeln(quality_setting);
	}
}

load: what,io
{
	if(what == SCENEMODE) // processing an ASCII scene file
	{
		kernel = io.read().asNum();
		quality_setting = io.read().asNum();

		plug_name_base = "iDof Post Blur:  ";
		plug_name_kernel = "amount= " + kernel;
		if(quality_setting == 1)
		{
			plug_name_quality = "  quality= Preview";
		}
		else
		{
			plug_name_quality = "  quality= Final";
		}
		
		plug_name = plug_name_base + plug_name_kernel + plug_name_quality;		
		setdesc(plug_name);
	}
}


//-------------------------------------
//Begin Custom Functions Here
//-------------------------------------

sample_for_current_pixel: ifo, i, j, quality_setting
{
	if(ifo.alpha[j,i] == 0)
	{
		put_red = ifo.red[j,i];
		put_green = ifo.green[j,i];
		put_blue = ifo.blue[j,i];		
		i = start_i;
		j = start_j;
	}
	else
	{
		//determine how many surrounding pixels to sample
		sample_size = integer((kernel)*ifo.alpha[j,i]);
		start_i = i;
		start_j = j;
		start_depth = ifo.depth[j,i];
		start_alpha = ifo.alpha[j,i];
		if(sample_size < 1)
		{
			sample_size = 1;
		}
		
		//define the grid height start of current sample area
		height_start = i - sample_size;
		if(height_start <= 1)
		{
			height_start = 1;
		}
		
		//define the grid height end of current sample area
		height_end = i + sample_size;
		if(height_end > ifo.height)
		{
			height_end = ifo.height;
		}
		
		//define the grid width start of current sample area
		width_start = j - sample_size;
		if(width_start <= 1)
		{
			width_start = 1;
		}
		
		//define the grid width end of current sample area
		width_end = j + sample_size;
		if(width_end > ifo.width)
		{
			width_end = ifo.width;
		}
		
		//use the start and end info to store all the rgb values for this tile in an array
		//we'll try this scanline style, scanning left to right, top to bottom.
		
		sum_red = 0;
		sum_green = 0;
		sum_blue = 0;
		//sum_alpha = 0;
		pixels_sampled = 0;
		
		for(i = height_start;i <= height_end;i++)           //start the vert loop
		{
			for(j = width_start;j <= width_end;j++)         //start the horiz loop
			{
				if(ifo.alpha[j,i] == 0)
				{
					if(ifo.depth[j,i] > start_depth)
					{
						alpha_multiplier = ifo.alpha[j,i];
						redbuffer = (number(ifo.red[j,i]))*alpha_multiplier;
						sum_red = sum_red + redbuffer;
						greenbuffer = (number(ifo.green[j,i]))*alpha_multiplier;
						sum_green = sum_green + greenbuffer;
						bluebuffer = (number(ifo.blue[j,i]))*alpha_multiplier;
						sum_blue = sum_blue + bluebuffer;
					
						if(quality_setting == 1)
						{
							random_j = random(0,(kernel/2));
							j= j + (kernel/2) + random_j;
						}
						else
						{
						}
						pixels_sampled = pixels_sampled + alpha_multiplier;
					}
					if(quality_setting == 1)
					{
						random_j = random(0,(kernel/2));
						j= j + (kernel/2) + random_j;
					}
					else
					{
					}	
				}
				else
				{
					if(ifo.alpha[j,i] == 1)
					{
						redbuffer = number(ifo.red[j,i]);
						sum_red = sum_red + redbuffer;
						greenbuffer = number(ifo.green[j,i]);
						sum_green = sum_green + greenbuffer;
						bluebuffer = number(ifo.blue[j,i]);
						sum_blue = sum_blue + bluebuffer;
						//alphabuffer = number(ifo.alpha[j,i]);
						//sum_alpha = sum_alpha + alphabuffer;
				
						if(quality_setting == 1)
						{
							random_j = random(0,(kernel/2));
							j= j + (kernel/2) + random_j;
						}
						else
						{
						}
						pixels_sampled++;
					}
					else
					{
							alpha_multiplier = ifo.alpha[j,i];
							redbuffer = (number(ifo.red[j,i]))*alpha_multiplier;
							sum_red = sum_red + redbuffer;

							if(ifo.red[j,i] >= 255)  {
								sum_red = sum_red + 20;  }
							
							greenbuffer = (number(ifo.green[j,i]))*alpha_multiplier;
							sum_green = sum_green + greenbuffer;
							
							if(ifo.green[j,i] >= 255)  {
								sum_green = sum_green + 20;  }
								
							bluebuffer = (number(ifo.blue[j,i]))*alpha_multiplier;
							sum_blue = sum_blue + bluebuffer;
						
							if(ifo.blue[j,i] >= 255)  {
								sum_blue = sum_blue + 20;  }
								
							if(quality_setting == 1)
							{
								random_j = random(0,(kernel/2));
								j= j + (kernel/2) + random_j;
							}
							else
							{
							}
							pixels_sampled = pixels_sampled + alpha_multiplier;
					}
				}

			//end horiz for loop here
			}
			if(quality_setting == 1)
			{
				random_i = random(0,(kernel/2));
				i = i + (kernel/2) + random_i;
			}
			else
			{
			}
		}
		
		//tile_width = width_end - width_start;
		//tile_height = height_end - height_start;
		//tile_height = 1;
		if(pixels_sampled != 0)
		{
			put_red = (number(sum_red) / pixels_sampled);
			put_green = (number(sum_green) / pixels_sampled);
			put_blue = (number(sum_blue) / pixels_sampled);
			//put_alpha = (number(sum_alpha) / pixels_sampled);
		}
		else
		{
			put_red = ifo.red[start_j,start_i];
			put_green = ifo.green[start_j,start_i];
			put_blue = ifo.blue[start_j,start_i];
		}
		
		i = start_i;
		j = start_j;
	}    
}

variable_fixing
{
	scenejustloaded = 0;
}

