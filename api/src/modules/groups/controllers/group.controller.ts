import type { NextFunction, Request, Response } from 'express';
import { GroupService } from '../services/group.service';
import type {
  AddMemberInput,
  CreateGroupInput,
  UpdateGroupInput,
} from '../validators/group.validator';

const groupService = new GroupService();

function body<T>(req: Request): T {
  return req.validated?.body as T;
}

function params<T>(req: Request): T {
  return req.validated?.params as T;
}

export class GroupController {
  async create(req: Request, res: Response, next: NextFunction) {
    try {
      const group = await groupService.createGroup(req.user!.id, body<CreateGroupInput>(req));
      res.status(201).json(group);
    } catch (err) {
      next(err);
    }
  }

  async list(req: Request, res: Response, next: NextFunction) {
    try {
      const groups = await groupService.listGroups(req.user!.id);
      res.status(200).json(groups);
    } catch (err) {
      next(err);
    }
  }

  async get(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId } = params<{ groupId: string }>(req);
      const group = await groupService.getGroup(groupId, req.user!.id);
      res.status(200).json(group);
    } catch (err) {
      next(err);
    }
  }

  async update(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId } = params<{ groupId: string }>(req);
      const group = await groupService.updateGroup(groupId, req.user!.id, body<UpdateGroupInput>(req));
      res.status(200).json(group);
    } catch (err) {
      next(err);
    }
  }

  async listMembers(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId } = params<{ groupId: string }>(req);
      const members = await groupService.listMembers(groupId, req.user!.id);
      res.status(200).json(members);
    } catch (err) {
      next(err);
    }
  }

  async removeMember(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId, userId } = params<{ groupId: string; userId: string }>(req);
      await groupService.removeMember(groupId, req.user!.id, userId);
      res.status(204).end();
    } catch (err) {
      next(err);
    }
  }

  async addMember(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId } = params<{ groupId: string }>(req);
      const member = await groupService.addMember(groupId, req.user!.id, body<AddMemberInput>(req));
      res.status(201).json(member);
    } catch (err) {
      next(err);
    }
  }

  async createInvitation(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId } = params<{ groupId: string }>(req);
      const invitation = await groupService.createInvitation(groupId, req.user!.id);
      res.status(201).json(invitation);
    } catch (err) {
      next(err);
    }
  }

  async acceptInvitation(req: Request, res: Response, next: NextFunction) {
    try {
      const { token } = params<{ token: string }>(req);
      const group = await groupService.acceptInvitation(token, req.user!.id);
      res.status(200).json(group);
    } catch (err) {
      next(err);
    }
  }
}
