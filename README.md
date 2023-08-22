# Using-spectral-analysis-and-mapping-to-enhance-the-harmonicity-of-a-sound
Research MATLAB Project which analyses Inharmonic sounds, tries to find its most likely fundamental frequency and harmonic template, and performs spectral mapping to make it sound more harmonic while retaining most of its sound quality.

Done at the University of Leeds, Music Multimedia and Electronics B.s.c., with supervisor David Moore.

## Spectral Mapping
While Sethares’ TransFormSynth performs spectral mapping upon single sinusoidal components only [Spectral Tools for Dynamic Tonality and Audio Morphing], our system additionally maps all the sinusoidal components belonging to the the peaks’ regions of the smoothed amplitude frequency spectrum of each frame (only if that peak comprehends a harmonic template’s frequency). This process is achieved via independent linear interpolation of the left and right side of the amplitude peak-regions; each peak-frequency of the source spectrum and the harmonic template are paired with a nearest-neighbor algorithm, similar to the one suggested by Sethares [Spectral Tools for Dynamic Tonality and Audio Morphing]. This process guarantees a more natural output sound, which presents more fidelity to the input audio file.

## Enhancing
Since, by their own nature, inharmonic sounds tend to contain high percentages of floor noise, a amplitude enhancing algorithm has been implemented in order to scale up the mapped peaks with lower amplitude while maintaining fixed the loudest peak in the spectrum, which is taken as ceiling amplitude reference for the enhancing process. Thus, all the mapped peaks can be enhanced up to infinity, but not beyond the amplitude level of the loudest peak. This operation is the best compromise between keeping the original characteristic nature of the input sound (by maintaining constant, at least until the amplitude of the loudest peak has been reached, the ratios between the peaks’ amplitude levels in the spectrum) and giving the user the possibility to enhance the harmonicity of the output sound.

## Spectral Analysis - Amplitude Smoothing
Due to the noisy nature of inharmonic signals and to the high number of data points, before calculating the number of peaks of each frame’s frequency spectrum, the signal needs to be smoothed in order to get rid of high-frequency fluctuations (noise). Without the smoothing (which is very similar to a low-pass filter), in fact, the number of peaks/minimas obtained would be too high.
Spectrum is smoothed and peak subsequently counted until target number of peaks is met.

## Peak Detection
The system classifies a peak region as the data between any two adjacent minima indices. Neighboring peak regions shared a minima point, such that they successively span the spectrum from the first to last identified minima indices.

## Fundamental Frequency Detection
The system uses the first detected peak region’s point of maxima as the fundamental frequency, from which the harmonic template is calculated. Importantly, this value is a bin index, and subsequent processes - including harmonic template calculation - operate without converting to frequency equivalents unnecessarily.

## Spectral Mapping
Spectral mapping is the core process of the system, responsible for any kind of harmonic transformation. An original warping algorithm is used to morph each detected and valid peak region, such that an existing maxima index - original peak - is quantised to its corresponding harmonic of the fundamental - destination peak.
A peak region is considered valid for spectral mapping if the original and destination peak both fall within of the region bounds by at least three indices. These constraints ensure the minimum requirements for the interpolation processing are met, and the bordering indices are left unprocessed for seamless substitution of the peak region back into the spectrum.
Initially, the unprocessed peak region is split into left and right parts at the largest value location. Interpolation is then performed to either side consecutively, in order to transform each data set to new horizontal dimensions. The degree of interpolation for the left side is determined by the factor difference between the original and destination peak. The degree of interpolation for the right side is automatically calculated with respect to the left, so that appending both data sets results in an output the same size as the input. Upon insertion of the processed peak region back into its original position, this last step is crucial in preventing unwanted data discontinuities and constraint breaches in the context of the entire spectrum.