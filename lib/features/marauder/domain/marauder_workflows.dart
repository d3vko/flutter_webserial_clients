import 'marauder_models.dart';

const marauderWorkflows = <MarauderWorkflow>[
  MarauderWorkflow(
    id: 'random-beacon-spam-list',
    name: 'Random Beacon Spam (List)',
    description:
        'Generates random SSIDs and broadcasts beacon frames using this list.',
    steps: [
      WorkflowStep(command: 'ssid -a -g 50', description: 'Generate 50 SSIDs'),
      WorkflowStep(command: 'list -s', description: 'Display SSIDs'),
      WorkflowStep(
        command: 'attack -t beacon -l',
        description: 'Beacon list attack',
      ),
    ],
  ),
  MarauderWorkflow(
    id: 'random-beacon-spam-auto',
    name: 'Random Beacon Spam (Auto)',
    description: 'Broadcasts beacons with auto-generated random SSIDs.',
    steps: [
      WorkflowStep(
        command: 'attack -t beacon -r',
        description: 'Random beacon spam',
      ),
    ],
  ),
  MarauderWorkflow(
    id: 'deauth-flood',
    name: 'Deauthentication Flood',
    description: 'Deauth flood on selected APs.',
    steps: [
      WorkflowStep(command: 'scanap'),
      WorkflowStep(command: 'list -a'),
      WorkflowStep(
        command: 'select -a {targets}',
        description: 'Select AP indices',
        requiresInput: true,
        inputLabel: 'Target AP indices (comma-separated)',
        placeholder: '0,1',
      ),
      WorkflowStep(command: 'list -a'),
      WorkflowStep(command: 'attack -t deauth'),
    ],
  ),
  MarauderWorkflow(
    id: 'evil-portal-serial',
    name: 'Evil Portal (Serial)',
    description: 'Upload portal HTML via serial and start Evil Portal.',
    steps: [
      WorkflowStep(
        command: 'evilportal -c sethtmlstr',
        description: 'Prepare HTML payload',
        requiresSerialPayload: true,
        serialPayloadLabel: 'Portal HTML',
        payloadDelayMs: 150,
      ),
      WorkflowStep(command: 'evilportal -c start'),
    ],
  ),
  MarauderWorkflow(
    id: 'karma-attack',
    name: 'Karma Attack',
    description: 'Enable Karma mode and background scan.',
    steps: [
      WorkflowStep(command: 'karma -p'),
      WorkflowStep(command: 'scanap'),
    ],
  ),
  MarauderWorkflow(
    id: 'mac-randomize',
    name: 'Stealth Mode (MAC Randomize)',
    description: 'Randomize AP and station MAC addresses.',
    steps: [
      WorkflowStep(command: 'randapmac'),
      WorkflowStep(command: 'randstamac'),
      WorkflowStep(command: 'info'),
    ],
  ),
  MarauderWorkflow(
    id: 'network-recon',
    name: 'Network Recon (Full)',
    description: 'Ping scan and port scan.',
    steps: [
      WorkflowStep(command: 'pingscan'),
      WorkflowStep(command: 'portscan'),
    ],
  ),
];
