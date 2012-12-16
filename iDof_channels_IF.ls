@version 2.0
@warnings
@script image
@name "iDof Channels"

//how bout some global declarations, hmmm?

info_icon = @ ".......11.......",
              "......1111......",
              ".......11.......",
              "................",
              ".......11.......",
              ".......11.......",
              ".......11.......",
              ".......11.......",
              ".......111......"
            @;

@define INFO      1

var scenejustloaded;
var optionsrunyet;
var camDOF;
var focalobject;
var focalobjectid;
var fstopobject;
var fstopobjectid;
var spread;
var spread_inverse;
var camera;
var cameraname;
var cameraid;
var focaldistance;
var fstopdistance;
var current_depth;
var current_frame;
var fadedistance;
var near_start_fade;
var far_start_fade;
var contentdir;
var scene;
var z;
var output_type = 1;
var black_point_name;
var white_point_name;
var write_rgb = true;
var write_r = true;
var write_g = true;
var write_b = true;
var write_alpha = true;
var write_tga = true;
var imgSeq_loc;
var imgSeq;
var Rdec;
var Gdec;
var Bdec;
var Adec;
var prenum;
var plug_name = "iDof Channels";
var icon;
var info_icon;

create
{
	icon[INFO] = Icon(info_icon);
	setdesc(plug_name);
	camDOF = getfirstitem(CAMERA);
	
	if(getfirstitem("center_point_IDOF"))
	{
		focalobject = getfirstitem("center_point_IDOF");
	}
	else
	{
		focalobject = getfirstitem(MESH);
	}
	
	if(getfirstitem("far_point_IDOF"))
	{
		fstopobject = getfirstitem("far_point_IDOF");
	}
	else
	{
		fstopobject = getfirstitem(MESH);
	}
	spread = 1;
	spread_inverse = 1;
	imgSeq_loc = "none";
	contentdir = getdir("Content");
	scenejustloaded = 0;
	optionsrunyet = 0;
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

	if(plug_name == "iDof Channels")
	{
	}
	else
	{       
		if(write_tga == true)
		{
			write_header(ifo);
		}
        
		scene = Scene();
		originaltime = scene.currenttime;
		originalframe = ifo.frame/scene.fps;
		z = 255;
		focalwpos = focalobject.getWorldPosition(originalframe);
		fstopwpos = fstopobject.getWorldPosition(originalframe);
		camwpos = camera.getWorldPosition(originalframe);
		focaldistance = number(vmag(extent(focalwpos,camwpos)));
		fstopdistance = number(vmag(extent(focalwpos,fstopwpos)));
		near_plane = focaldistance - fstopdistance;
		far_plane = focaldistance + fstopdistance;
		if(spread != 0)
		{
			fadedistance = fstopdistance*spread;
			far_start_fade = (fadedistance + focaldistance);
			near_start_fade = (focaldistance - fadedistance);
		}

		if(runningUnder() != SCREAMERNET)
		{
			moninit(ifo.height);
		}
		for(i = ifo.height;i >= 1;i--)	//vert loop
		{
			for(j = 1;j <= ifo.width;j++)	//horiz loop
			{
				//get the depth for the current pixel
				current_depth = ifo.depth[j,i];
				if(spread == 0)
				{
					if(current_depth >= near_plane && current_depth <= far_plane)
					{
						if(output_type == 2)
						{
							g = 1.0;
							b = 0.0;
							r = 0.0;
						}
						z = 0.0;
					}
					if(current_depth > far_plane)
					{
						if(output_type == 2)
						{
							g = 0.0;
							b = 1.0;
							r = 0.0;
						}
						z = 255;
					}
					if(current_depth < near_plane)
					{
						if(output_type == 2)
						{
							g = 0.0;
							b = 0.0;
							r = 1.0;
						}
						z = 255;
					}
				}
				else
				{
					if(far_plane > current_depth && current_depth >= far_start_fade)
					{
						z = integer(((current_depth - far_start_fade) / (fstopdistance - fadedistance)) * 255);
						if(output_type == 2)
						{
							g = (255 - z)/255;
							b = z/255;
							r = 0.0;
						}
					}
					if(near_plane < current_depth && current_depth <= near_start_fade)
					{
						z = integer(((near_start_fade - current_depth) / (fstopdistance - fadedistance)) * 255);
						if(output_type == 2)
						{
							g = (255 -z)/255;
							b = 0.0;
							r = z/255;
						}
					}
					if(current_depth <= near_plane)
					{
						z = 255.0;
						if(output_type == 2)
						{
							g = 0.0;
							b = 0.0;
							r = 1.0;
						}
					}
					if(current_depth >= far_plane)
					{
						z = 255.0;
						if(output_type == 2)
						{
							g = 0.0;
							b = 1.0;
							r = 0.0;
						}
					}
					if(current_depth > near_start_fade && current_depth < far_start_fade)
					{
						z = 0.0;
						if(output_type == 2)
						{
							g = 1.0;
							b = 0.0;
							r = 0.0;
						}
					}
				}
				if(write_r == true)
				{
					ifo.red[j,i] = z/255;
				}
				if(write_g == true)
				{
					ifo.green[j,i] = z/255;
				}
				if(write_b == true)
				{
					ifo.blue[j,i] = z/255;
				}
				if(write_alpha == true)
				{
					ifo.alpha[j,i] = z/255;
				}
				if(write_rgb == true)
				{
					ifo.red[j,i] = r;
					ifo.green[j,i] = g;
					ifo.blue[j,i] = b;
				}
				if(write_tga == true)
				{
					if(output_type == 1)
					{
						Rdec = z;
						Gdec = z;
						Bdec = z;
						Adec = ifo.alpha[j,i]*255;
					}
					if(output_type == 2)
					{
						Rdec = r*255;
						Gdec = g*255;
						Bdec = b*255;
						Adec = ifo.alpha[j,i]*255;
					}
				
					tgaSwatch(Rdec,Gdec,Bdec,Adec);
				}
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
        if(write_tga == true)
        {
        	imgSeq.close();
        }
        
        //some cleanup so things refresh
    	originaltime = nil;
		originalframe = nil;
    	z = nil;
    	focalwpos =nil;
    	fstopwpos = nil;
    	camwpos = nil;
    	focaldistance = nil;
    	fstopdistance = nil;
	}
}

options
{
	if(scenejustloaded == 1)
	{
		variable_fixing();
	}

	if(output_type == 1)
	{
		black_point_name = "Black Point";
		white_point_name = "White Point";
	}
	if(output_type == 2)
	{
		black_point_name = "Green Point";
		white_point_name = "R / B Point";
	}
	
    t1text = "Channel Output:";
    t2text = "Control Objects:";
    if(!reqbegin("iDof 3.2"))
        return;
    reqsize(240,475);
    i1 = ctlimage("idof_3.tga",3,2,,234,63);    
	t1 = ctltext("",t1text);
	
	c0 = ctlpopup("Matte Type",output_type,@"Greyscale","RGB"@);
	
	c1_15 = ctlcheckbox("Write to RGB Channels",write_rgb);
	ctlactive(c0,"rgb_invisible",c1_15);
	c1  =  ctlcheckbox("Write to Red Channel   ",write_r);
	ctlactive(c0,"rgb_visible",c1);
	
	c1_1 = ctlcheckbox("Write to Green Channel",write_g);
	ctlactive(c0,"rgb_visible",c1_1);
	
	c1_2 = ctlcheckbox("Write to Blue Channel  ",write_b);
	ctlactive(c0,"rgb_visible",c1_2);
	c1_3 = ctlcheckbox("Write to Alpha Channel",write_alpha);
	ctlactive(c0,"rgb_visible",c1_3);
	c1_4 = ctlcheckbox("Write to TGA Sequence ",write_tga);
	c1_5 = ctlfilename("Prefix",imgSeq_loc);
	ctlactive(c1_4,"seq_active",c1_5);
	s2 = ctlsep();
	t2 = ctltext("",t2text);
	c2 = ctlcameraitems("Camera",camDOF);
	
	//c3 = ctlmeshitems(black_point_name,focalobject);
	c3 = ctlmeshitems("Center Point",focalobject);
	
	//c4 = ctlmeshitems(white_point_name,fstopobject);
	c4 = ctlmeshitems("Far Point",fstopobject);
	
	c5 = ctlpercent("Spread",spread_inverse);
	c6 = ctlbutton("" + icon[INFO],25,"spread_info_button");
	ctlposition(c6,175,411);

	if(reqpost())
	{
		output_type = getvalue(c0);
		write_rgb = getvalue(c1_15);
		write_r = getvalue(c1);
		write_g = getvalue(c1_1);
		write_b = getvalue(c1_2);
		write_alpha = getvalue(c1_3);
		write_tga = getvalue(c1_4);
		imgSeq_loc = getvalue(c1_5);
		camDOF = getvalue(c2);
		focalobject = getvalue(c3);
		fstopobject = getvalue(c4);
		spread_inverse = getvalue(c5);
		optionsrunyet = 1;
		spread = 1 - spread_inverse;
		if(spread <= 0)
		{
		   spread = .0001;
		}
		if(spread >= 1)
		{
			spread = .9999;
		}

		if(camDOF != nil)
		{
			camera = camDOF.name;
			cameraid = camDOF.id;
		}
		
		if(focalobject != nil)
		{
			objectname = focalobject.name;
			focalobjectid = focalobject.id;
		}
		if(fstopobject != nil)
		{
			object2name = fstopobject.name;
			fstopobjectid = fstopobject.id;
		}
		focalobject = getagentbyid(focalobjectid);
		fstopobject = getagentbyid(fstopobjectid);
		camera = getagentbyid(cameraid);
		
		if(output_type == 1)
		{
			write_rgb = false;
		}
		if(output_type == 2)
		{
			write_r = false;
			write_g = false;
			write_b = false;
			write_alpha = false;
		}
                
		plug_name_base = "iDof Filtering Channels: ";
		
		if(write_r == true)
		{
			plug_name_r = " R ";
		}
		else
		{
			plug_name_r = " ";
		}
		if(write_g == true)
		{
			plug_name_g = " G ";
		}
		else
		{
			plug_name_g = " ";
		}
		if(write_b == true)
		{
			plug_name_b = " B ";
		}
		else
		{
			plug_name_b = " ";
		}
		if(write_alpha == true)
		{
			plug_name_alpha = " +A ";
		}
		else
		{
			plug_name_alpha = "";
		}
		if(write_rgb == true)
		{
			plug_name_r = " RGB ";
			plug_name_g = "";
			plug_name_b = "";
			plug_name_alpha = "";
		}
		else
		{
		}
		if(write_tga == true)
		{
			plug_name_tga = " +TGA";
		}
		else
		{
			plug_name_tga = "";
		}
		plug_name = plug_name_base + plug_name_r + plug_name_g + plug_name_b + plug_name_alpha + plug_name_tga;		
		setdesc(plug_name);
	}
}

save: what,io
{
	if(what == SCENEMODE)
	{
		if(optionsrunyet == 0)
		{
		   variable_fixing();
		}
	   io.writeln(output_type);
	   io.writeln(write_rgb);
	   io.writeln(write_r);
	   io.writeln(write_g);
	   io.writeln(write_b);
	   io.writeln(write_alpha);
	   io.writeln(write_tga);
	   io.writeln(imgSeq_loc);
	   //io.writeln(camDOF);
	   //io.writeln(camera);
	   io.writeln(cameraid);
	   //io.writeln(focalobject);
	   io.writeln(focalobjectid);
	   //io.writeln(fstopobject);
	   io.writeln(fstopobjectid);
	   io.writeln(spread_inverse);
	}
}

load: what,io
{
	if(what == SCENEMODE) // processing an ASCII scene file
	{
		output_type = io.read().asInt();
		write_rgb = io.read().asInt();  //added .asInt on April 08, 2006 to test as a fix
		if(write_rgb == 1)
			write_rgb = true;

		write_r = io.read();
		if(write_r == 1)
		{
			write_r = true;
		} else {
			write_r = false;
		}

		write_g = io.read();
		if(write_g == 1)
		{
			write_g = true;
		} else {
			write_g = false;
		}

		write_b = io.read();
		if(write_b == 1)
		{
			write_b = true;
		} else {
			write_b = false;
		}
		
		write_alpha = io.read();
		if(write_alpha == 1)
		{
			write_alpha = true;
		} else {
			write_alpha = false;
		}
		
		write_tga = io.read();
		if(write_tga == 1)
		{
			write_tga = true;
		} else {
			write_tga = false;
		}
		
		imgSeq_loc_reminder = io.read();
		if(imgSeq_loc_reminder != nil  && imgSeq_loc_reminder != "none")
		{
			imgSeq_loc = imgSeq_loc_reminder;
		}
		//camDOF_reminder = io.read();
		//camera_reminder = io.read();
		cameraid = io.read().asInt();
		//focalobject_reminder = io.read();
		focalobjectid = io.read().asInt();
		//fstopobject_reminder = io.read();
		fstopobjectid = io.read().asInt();
		spread_inverse = io.read().asNum();
		
		//camDOF = camera_reminder;
		//focalobject = focalobject_reminder;
		//fstopobject = fstopobject_reminder;
		
		optionsrunyet = 0;
		variable_fixing();
       
		plug_name_base = "iDof Filtering Channels: ";
		if(write_r == true)
		{
			plug_name_r = " R ";
		}
		else
		{
			plug_name_r = " ";
		}
		if(write_g == true)
		{
			plug_name_g = " G ";
		}
		else
		{
			plug_name_g = " ";
		}
		if(write_b == true)
		{
			plug_name_b = " B ";
		}
		else
		{
			plug_name_b = " ";
		}
		if(write_alpha == true)
		{
			plug_name_alpha = " +A ";
		}
		else
		{
			plug_name_alpha = "";
		}
		 if(write_rgb == true)
		{
			plug_name_r = " RGB ";
			plug_name_g = "";
			plug_name_b = "";
			plug_name_alpha = "";
		}

		if(write_tga == true)
		{
			plug_name_tga = " +TGA";
		}
		else
		{
			plug_name_tga = "";
		}
		plug_name = plug_name_base + plug_name_r + plug_name_g + plug_name_b + plug_name_alpha + plug_name_tga;		
		setdesc(plug_name);
       
		scenejustloaded = 1;
	}
}

spread_info_button
{
	info("This works kind of like a spotlight's spread parameter.   (1/5)");
	info("100% is a perfect fade from center point to far point.   (2/5)");
	info("Lowering the percentage extends the center area further proportionately.   (3/5)");
	info("50% extends the center area halfway to the far point before starting the fade.   (4/5)");
	info("0% is no fade.  You'll have a hard line between center and far.   (5/5)");
}

variable_fixing
{
	spread = 1 - spread_inverse;
	if(spread <= 0)
	{
		spread = .0001;
	}
	if(spread >= 1)
	{
		spread = .9999;
	}
	
	if(camDOF != nil)
	{
		camera = camDOF.name;
		cameraid = camDOF.id;
	}

	/*
	if(focalobject != nil)
	{
		objectname = focalobject.name;
		focalobjectid = focalobject.id;
	}
	if(fstopobject != nil)
	{
		object2name = fstopobject.name;
		fstopobjectid = fstopobject.id;
	}
	*/

	focalobject = getagentbyid(focalobjectid);
	if(optionsrunyet != 0)
	{
		focalobject = focalobject.name;
	}
	fstopobject = getagentbyid(fstopobjectid);
	if(optionsrunyet != 0)
	{
		fstopobject = fstopobject.name;
	}
	camera = getagentbyid(cameraid);
	camDOF = getagentbyid(cameraid);
	if(optionsrunyet != 0)
	{
		camDOF = camDOF.name;
	}
	if(imgSeq_loc_reminder != nil  && imgSeq_loc_reminder != "none")
	{
		imgSeq_loc = imgSeq_loc_reminder;
	}

	scenejustloaded = 0;
}

getagentbyid:id
{
	item=Mesh();
	while(item)
	{
		if (item.id==id)
			return item;
		mybone=item.bone();
		while(mybone)
		{
			if(mybone.id==id)
				return mybone;
			mybone=mybone.next();
		}
		item=item.next();
    }

	item=Light();
	while(item)
	{
		if (item.id==id)
			return item;
		item=item.next();
	}

	item=Camera();
	while(item)
	{
		if (item.id==id)
			return item;
		item=item.next();
	}
	return (nil);
}

getSelected
{
	if(sceneObj.getSelect())
	{
		selItems = sceneObj.getSelect();
		selID = selItems[1].id;
	}
}

tgaSwatch: Rdec,Gdec,Bdec,alpha  //___Send it a decimal RGB value, an image number, and a directory to write the image
{
	//_______________________________________________Write RGB data___________________
	imgSeq.writeByte(Bdec);
	imgSeq.writeByte(Gdec);
	imgSeq.writeByte(Rdec);
	imgSeq.writeByte(Adec);
}

seq_active: value
{
	return(value);
}

write_header: ifo
{
	if(ifo.frame < 1000)
	{
		if(ifo.frame < 100)
		{
			if(ifo.frame < 10)
			{
				prenum_string = "000";
			} else {
				prenum_string = ("00");
			}
		} else {
			prenum_string = "0";
		}
	} else {
		prenum_string = "";
	}
	prenum = ifo.frame;
	filename = string(imgSeq_loc,prenum_string,prenum,".tga");
	imgSeq = File(filename,"wb");
        
	//________________________________________________________Write TGA header
	imgSeq.writeByte(0);  //____ID Length (Ignored)
	imgSeq.writeByte(0);  //____ColorMapType (Ignored)
	imgSeq.writeByte(2);  //____Image Type 2: Truecolor Image

	for(i = 1; i <= 9; ++i)  
	{
		imgSeq.writeByte(0);
	}
	width_var = ifo.width;
	height_var = ifo.height;
        
	imgSeq.writeByte(width_var);  //____x width
	if(width_var <= 255)
	{
		width_multiplier = 0;
	}
	else
	{
		width_multiplier = integer(width_var/256);
	}
	imgSeq.writeByte(width_multiplier);
	imgSeq.writeByte(height_var);  //____y height
	if(height_var <= 255)
	{
		height_multiplier = 0;
	}
	else
	{
		height_multiplier = integer(height_var/256);
	}
	imgSeq.writeByte(height_multiplier);
	imgSeq.writeByte(32);  //____bit-depth 24 
	imgSeq.writeByte(8);   //____descriptor, 0 for 24bit, 8 for 32bit
}

rgb_visible: value
{
	if(value == 1)
	{
		return(value);
	}
	else
	{
		return(0);
	}
}

rgb_invisible: value
{
	if(value == 1)
	{
		return(0);
	}
	else
	{
		return(value);
	}
}

