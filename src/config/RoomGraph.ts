export type RoomId =
  | 'stage'
  | 'leftHall'
  | 'rightHall'
  | 'backstage'
  | 'bathroom'
  | 'eastHall'
  | 'backVent'
  | 'showFloor'
  | 'officeLeft'   // adjacent to left door — girl is visible/audible here
  | 'officeRight'  // adjacent to right vent
  | 'officeBack';  // adjacent to back vent

export interface Room {
  id: RoomId;
  label: string;
  cameraIndex: number; // -1 = no camera (office-adjacent)
  adjacent: RoomId[];
  isVent: boolean;
  isDoor: boolean;
}

export const ROOMS: Record<RoomId, Room> = {
  stage: {
    id: 'stage',
    label: 'Stage',
    cameraIndex: 0,
    adjacent: ['leftHall', 'rightHall', 'backstage', 'showFloor'],
    isVent: false,
    isDoor: false,
  },
  showFloor: {
    id: 'showFloor',
    label: 'Show Floor',
    cameraIndex: 7,
    adjacent: ['stage', 'leftHall', 'rightHall', 'bathroom'],
    isVent: false,
    isDoor: false,
  },
  leftHall: {
    id: 'leftHall',
    label: 'Left Hall',
    cameraIndex: 1,
    adjacent: ['stage', 'showFloor', 'officeLeft'],
    isVent: false,
    isDoor: false,
  },
  rightHall: {
    id: 'rightHall',
    label: 'Right Hall',
    cameraIndex: 2,
    adjacent: ['stage', 'showFloor', 'officeRight'],
    isVent: false,
    isDoor: false,
  },
  backstage: {
    id: 'backstage',
    label: 'Backstage',
    cameraIndex: 3,
    adjacent: ['stage', 'backVent'],
    isVent: false,
    isDoor: false,
  },
  bathroom: {
    id: 'bathroom',
    label: 'Bathroom',
    cameraIndex: 4,
    adjacent: ['showFloor', 'eastHall'],
    isVent: false,
    isDoor: false,
  },
  eastHall: {
    id: 'eastHall',
    label: 'East Hall',
    cameraIndex: 5,
    adjacent: ['bathroom', 'officeRight'],
    isVent: false,
    isDoor: false,
  },
  backVent: {
    id: 'backVent',
    label: 'Back Vent',
    cameraIndex: 6,
    adjacent: ['backstage', 'officeBack'],
    isVent: true,
    isDoor: false,
  },
  officeLeft: {
    id: 'officeLeft',
    label: 'Left Door',
    cameraIndex: -1,
    adjacent: ['leftHall'],
    isVent: false,
    isDoor: true,
  },
  officeRight: {
    id: 'officeRight',
    label: 'Right Vent',
    cameraIndex: -1,
    adjacent: ['rightHall', 'eastHall'],
    isVent: true,
    isDoor: true,
  },
  officeBack: {
    id: 'officeBack',
    label: 'Back Vent',
    cameraIndex: -1,
    adjacent: ['backVent'],
    isVent: true,
    isDoor: true,
  },
};

export const CAMERA_ROOMS: RoomId[] = [
  'stage',      // CAM 1
  'leftHall',   // CAM 2
  'rightHall',  // CAM 3
  'backstage',  // CAM 4
  'bathroom',   // CAM 5
  'eastHall',   // CAM 6
  'backVent',   // CAM 7
  'showFloor',  // CAM 8
];
