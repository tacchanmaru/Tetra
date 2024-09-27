/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Guess Together group activity definition.
*/

import CoreTransferable
import GroupActivities

struct TetraActivity: GroupActivity, Transferable {
    var metadata: GroupActivityMetadata = {
        var metadata = GroupActivityMetadata()
        metadata.title = "Tetra"
        return metadata
    }()
}
