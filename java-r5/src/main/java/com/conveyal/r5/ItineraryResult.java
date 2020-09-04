package com.conveyal.r5;

import com.conveyal.r5.profile.Path;
import gnu.trove.list.TIntList;
import gnu.trove.list.array.TIntArrayList;
import gnu.trove.map.TObjectIntMap;

import java.util.List;

public class ItineraryResult {
    /** A list of unique paths, each one associated with a positive integer index by its position in the list. */
    public final List<Path> pathForIndex;

    /** The inverse of pathForIndex, giving the position of each path within that list. Used to deduplicate paths. */
    public final TObjectIntMap<Path> indexForPath;

    /** The total number of targets for which we're recording paths, i.e. width * height of the destination grid. */
    public final int nTargets;

    /**
     * The number of paths being recorded at each destination location.
     * This may be much smaller than the number of iterations (MC draws). We only want to record a few paths with
     * travel times near the selected percentile of travel time.
     */
    public final int nPathsPerTarget;

    /**
     * For each target, the index number of N paths that reach that target at roughly a selected percentile
     * of all observed travel times. This is a flattened width * height * nPaths array.
     */
    public final TIntList pathIndexes;

    public ItineraryResult(List<Path> pathForIndex, TObjectIntMap<Path> indexForPath, TIntList pathIndexes,
                           int nTargets, int nPathsPerTarget) {
        this.pathForIndex = pathForIndex;
        this.indexForPath = indexForPath;
        this.pathIndexes = pathIndexes;
        this.nTargets = nTargets;
        this.nPathsPerTarget = nPathsPerTarget;
    }
}
