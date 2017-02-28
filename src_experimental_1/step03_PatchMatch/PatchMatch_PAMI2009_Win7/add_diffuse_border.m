function color_bordered_image = add_diffuse_border(image, boundary_width)

%given an image, will add a diffuse border of boundary_width on all sides.
%the color in that border will be diffused color from near the border.

%aftewards, increasing amounts of noise will be added towards the ultimate
%border

fprintf('\nAdding diffuse and noise border around image\n');

width  = size(image,2) + 2*boundary_width;
height = size(image,1) + 2*boundary_width;

color_bordered_image = zeros(height, width, 3);

color_bordered_image(boundary_width + 1:height-boundary_width, ...
                     boundary_width + 1:width -boundary_width,:) = image;
            
%1 means done synthesizing.  0 means not synthesized
to_synthesize_mask = zeros(height, width);
to_synthesize_mask(boundary_width + 1:height-boundary_width, ...
                   boundary_width + 1:width -boundary_width) = 1;

%we want to fill, in onion peel order, all the pixels in the boundary by
%diffusion.  So we want to work from the inside out.  we need a distance
%transform

%lets do this at half resolution, and then use the full res to_synthesize
%mask to take the expanded low res stuff.

fprintf(' downsampling image for speed up\n');

small_image = imresize(color_bordered_image, floor([height/2 width/2]), 'nearest');
small_mask  = imresize(to_synthesize_mask, floor([height/2 width/2]), 'nearest');

% small_image(:,:,1) = small_image(:,:,1) .* small_mask;
% small_image(:,:,2) = small_image(:,:,2) .* small_mask;
% small_image(:,:,3) = small_image(:,:,3) .* small_mask;

distance_image = bwdist(small_mask);

[to_synthesize_y, to_synthesize_x, distance_v] = find(distance_image);

%sort them by order of distance from finished area
[distance_v, idx] = sort(distance_v + rand(size(distance_v))*.01);  %adding small random amount to break ties randomly.
to_synthesize_y = to_synthesize_y(idx);
to_synthesize_x = to_synthesize_x(idx);

diffuse_radius = 2;

size(to_synthesize_y,1)

tic
for i = 1:size(to_synthesize_y,1)
    %set the pixel equal to the average of the valid pixels around it
    
    current_y = to_synthesize_y(i);
    current_x = to_synthesize_x(i);  
    
    y_min = max(1, current_y - diffuse_radius);
    y_max = min(floor(height/2), current_y + diffuse_radius);
    x_min = max(1, current_x - diffuse_radius);
    x_max = min(floor(width/2), current_x + diffuse_radius);
    
    local_mask   = small_mask(y_min:y_max, x_min:x_max);
    local_colors = small_image(y_min:y_max, x_min:x_max, :);

    average_color = sum(sum(local_colors))/sum(sum(local_mask));

    small_image(current_y, current_x,:) = average_color;
    small_mask( current_y, current_x)   = 1;
    
    if(mod(i,1000)==0)
        fprintf('.');
    end
  
    if(mod(i,20000) == 0 || i == size(to_synthesize_y,1))
        %figure(3)
        %imshow(small_image)
        fprintf(' %.2f %% \n', 100*i/size(to_synthesize_y,1));
       % pause(.01)
    end
end
fprintf('\n');
toc

fprintf(' upsampling border\n');
%now upsample.
upsamp_image = imresize(small_image, [height width], 'nearest');

%this is so annoying that matlab won't allow you to do a matrix access with
%such as upsamp_image(logical(1-to_synthesize_mask),1).  You have to do a
%separate access for each channel.  This stupid hack is a way around that,
%making the logical matrix 3 channel
stupid_hack_image = zeros(size(color_bordered_image));
stupid_hack_image(:,:,1) = 1-to_synthesize_mask;
stupid_hack_image(:,:,2) = 1-to_synthesize_mask;
stupid_hack_image(:,:,3) = 1-to_synthesize_mask;

color_bordered_image(logical(stupid_hack_image)) = upsamp_image(logical(stupid_hack_image));

%we'll use distance image as a weight for adding noise
distance_image = bwdist(to_synthesize_mask);
distance_image = distance_image / max(max(distance_image));

fprintf('Adding noise\n');
noise_image = 1.5*rand(height, width, 3)-0.5; %0 centered noise

noise_image(:,:,1) = noise_image(:,:,1) .* distance_image;
noise_image(:,:,2) = noise_image(:,:,2) .* distance_image;
noise_image(:,:,3) = noise_image(:,:,3) .* distance_image;

color_bordered_image = color_bordered_image + noise_image;

color_bordered_image(color_bordered_image < 0) = 0;
color_bordered_image(color_bordered_image > 1) = 1;

%figure(3)
%imshow(color_bordered_image)
%pause(.01)