function sleepms(ms)
	x=clocktotime(clock);
	y=clocktotime(clock);
	while ( 1000*(y-x) < ms )
		y = clocktotime(clock);
	end