# @ImageJ IJ

import os
from ij import IJ

# Set the experiment path
experiment_path = "/PATH_TO_EXPERIMENT_DATA_DIR" # This contains multiple positions
output_root = "/PATH_TO_OUTPUT_DIR" # New directories for each position will be generated

# Assign channel names, frame range, and output file name of transformation results
channels = ["2-CFP", "4-FRET", "5-YFP", "0-BF", "1-BFP", "8-RFP"]
frame_range = (1, 401)
tf = "/TransformationMatrices.txt"

# Get a list of positions
positions = [pos for pos in os.listdir(experiment_path) if os.path.isdir(os.path.join(experiment_path, pos))]

# Function to subset the stack to the desired frame range
def subset_stack(stack, frame_range):
    start_frame, end_frame = frame_range
    total_frames = stack.getStackSize()
    if start_frame < 1 or end_frame > total_frames:
        raise ValueError("Frame range %s is out of bounds for stack with %s frames." % (str(frame_range), str(total_frames)))
    IJ.run(stack, "Make Substack...", "frames=%s-%s" % (start_frame, end_frame))
    return IJ.getImage()

# Function to save the registered stack
def save_registered_stack(output_path, channel, stack, save_as_sequence):
    if save_as_sequence:
        # Save as sequence of images
        IJ.run("Image Sequence... ", "select=%s dir=%s format=TIFF use" % (output_path, output_path))
    else:
        # Save as single TIFF stack
        output_file = os.path.join(output_path, "%s_registered.tif" % channel)
        IJ.saveAsTiff(stack, output_file)

# Function to register stacks for a single position
def register_stack(position_path, output_path, channels, frame_range, tf, save_as_sequence):
    print("Processing position: %s" % position_path)
    if not os.path.exists(output_path):
        os.makedirs(output_path)

    try:
        # Load the reference channel
        IJ.run("Image Sequence...", "open=%s/img_000000000_0-BF_000.tif number=%s scale=100 file=%s sort" % (position_path, frame_range[1], channels[0]))
        ref_stack1 = IJ.getImage()
        ref_stack2 = subset_stack(ref_stack1, frame_range)
        IJ.run(ref_stack2, "MultiStackReg", "action_1=Align file_1=[%s] stack_2=None action_2=Ignore file_2=[%s] transformation=[Rigid Body] save" % (output_path + tf, output_path + tf))
        ref_stack1.close()
        ref_stack2.close()

        # Process all channels
        for channel in channels:
            IJ.run("Image Sequence...", "open=%s/img_000000000_0-BF_000.tif number=%s scale=100 file=%s sort" % (position_path, frame_range[1], channel))
            channel_stack1 = IJ.getImage()
            channel_stack2 = subset_stack(channel_stack1, frame_range)
            IJ.run(channel_stack2, "MultiStackReg", "load=%s" % (output_path + tf))

            # Save the registered stack
            save_registered_stack(output_path, channel, channel_stack2, save_as_sequence)
            
            channel_stack1.close()
            channel_stack2.close()

    except Exception as e:
        print("Error processing position %s: %s" % (position_path, str(e)))

# Batch processing function
def batch_register_positions(experiment_path, output_root, positions, channels, frame_range, tf, save_as_sequence):
    for pos in positions:
        position_path = os.path.join(experiment_path, pos)
        output_path = os.path.join(output_root, pos)
        register_stack(position_path, output_path, channels, frame_range, tf, save_as_sequence)

# Run batch processing
save_as_sequence = True  # Set to False for single TIFF stack, True for sequence of images
#positions=["Pos2","Pos3","Pos4","Pos5","Pos6","Pos7","Pos8","Pos9"] # If you don't need to perform for all positions, specify your positions here
batch_register_positions(experiment_path, output_root, positions, channels, frame_range, tf, save_as_sequence)